import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "ruler")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                // App title
                VStack(spacing: 8) {
                    Text("LevelMap")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("AR Floor Verification")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Loading indicator
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Initializing...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Feature highlights
                VStack(spacing: 12) {
                    FeatureRow(icon: "camera.fill", text: "AR Plane Detection")
                    FeatureRow(icon: "ruler.fill", text: "AI Measurement Reading")
                    FeatureRow(icon: "chart.bar.fill", text: "Professional Reports")
                }
                .padding(.top, 40)
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    LoadingView()
}
