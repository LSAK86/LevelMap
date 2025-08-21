import Foundation
import AuthenticationServices
import Combine

// MARK: - Authentication Service

class AuthService: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    
    override init() {
        super.init()
        loadUserFromDefaults()
    }
    
    // MARK: - Public Methods
    
    func checkSignInStatus() {
        if let user = currentUser {
            isSignedIn = true
            // Verify token validity if needed
        }
    }
    
    func signInWithApple() async throws {
        isLoading = true
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let result = try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate { result in
                continuation.resume(with: result)
            }
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            
            // Store delegate to prevent deallocation
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization as? ASAuthorizationAppleIDCredential {
                let user = User(
                    id: appleIDCredential.user,
                    email: appleIDCredential.email,
                    fullName: appleIDCredential.fullName?.formatted(),
                    identityToken: appleIDCredential.identityToken,
                    authorizationCode: appleIDCredential.authorizationCode
                )
                
                await MainActor.run {
                    self.currentUser = user
                    self.isSignedIn = true
                    self.saveUserToDefaults(user)
                }
            }
        case .failure(let error):
            throw AuthError.signInFailed(error)
        }
        
        isLoading = false
    }
    
    func signOut() {
        currentUser = nil
        isSignedIn = false
        userDefaults.removeObject(forKey: userKey)
    }
    
    func refreshUserData() async throws {
        guard let user = currentUser else {
            throw AuthError.notSignedIn
        }
        
        // In a real app, you would refresh the user's data from your backend
        // For now, we'll just simulate a successful refresh
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        await MainActor.run {
            // Update user data if needed
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUserFromDefaults() {
        if let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isSignedIn = true
        }
    }
    
    private func saveUserToDefaults(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: userKey)
        }
    }
}

// MARK: - Supporting Types

struct User: Codable {
    let id: String
    let email: String?
    let fullName: String?
    let identityToken: Data?
    let authorizationCode: Data?
    
    var displayName: String {
        return fullName ?? email ?? "Unknown User"
    }
}

enum AuthError: Error, LocalizedError {
    case notSignedIn
    case signInFailed(Error)
    case signOutFailed
    case refreshFailed
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in"
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .signOutFailed:
            return "Sign out failed"
        case .refreshFailed:
            return "Failed to refresh user data"
        }
    }
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Apple Sign In")
        }
        return window
    }
}
