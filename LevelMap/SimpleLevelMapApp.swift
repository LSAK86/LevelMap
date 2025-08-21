import SwiftUI

@main
struct SimpleLevelMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "ruler")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("LevelMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AR Floor Verification")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    Button("Start New Session") {
                        // TODO: Implement AR session
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("View Projects") {
                        // TODO: Show projects
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Settings") {
                        // TODO: Show settings
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("LevelMap")
        }
    }
}

#Preview {
    ContentView()
}
