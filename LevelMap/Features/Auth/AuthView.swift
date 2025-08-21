import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("LevelMap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AR Floor Level Verification")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Sign In Section
                VStack(spacing: 20) {
                    Text("Get Started")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Sign in to access your projects and measurements")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                do {
                                    try await authService.signInWithApple()
                                } catch {
                                    await MainActor.run {
                                        showingError = true
                                    }
                                }
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    
                    if authService.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(.top, 10)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 10) {
                    Text("Professional floor level verification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Powered by ARKit & AI")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }
            .padding()
            .alert("Sign In Failed", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Please try again or contact support if the problem persists.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SignInWithAppleButton: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleSignIn), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void, onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handleSignIn() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window available for Apple Sign In")
            }
            return window
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
}
