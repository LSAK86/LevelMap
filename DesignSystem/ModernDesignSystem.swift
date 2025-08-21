import SwiftUI

// MARK: - Modern Design System
struct ModernDesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color("PrimaryBlue")
        static let primaryLight = Color("PrimaryBlueLight")
        static let primaryDark = Color("PrimaryBlueDark")
        
        // Secondary Colors
        static let secondary = Color("SecondaryPurple")
        static let accent = Color("AccentOrange")
        
        // Semantic Colors
        static let success = Color("SuccessGreen")
        static let warning = Color("WarningYellow")
        static let error = Color("ErrorRed")
        static let info = Color("InfoBlue")
        
        // Neutral Colors
        static let background = Color("BackgroundColor")
        static let surface = Color("SurfaceColor")
        static let card = Color("CardColor")
        static let text = Color("TextColor")
        static let textSecondary = Color("TextSecondaryColor")
        static let border = Color("BorderColor")
        
        // AR Colors
        static let arGrid = Color.green.opacity(0.6)
        static let arSelected = Color.blue.opacity(0.8)
        static let arLaser = Color.red
        static let arPlane = Color.blue.opacity(0.3)
    }
    
    // MARK: - Typography
    struct Typography {
        // Display
        static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
        
        // Headlines
        static let headlineLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
        
        // Titles
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let titleMedium = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let titleSmall = Font.system(size: 14, weight: .medium, design: .rounded)
        
        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .rounded)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .rounded)
        
        // Labels
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .rounded)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        static let extraLarge = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Modern Components
struct ModernPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(ModernDesignSystem.Typography.labelLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [ModernDesignSystem.Colors.primary, ModernDesignSystem.Colors.primaryDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
            .shadow(color: ModernDesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

struct ModernSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(ModernDesignSystem.Typography.labelLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(ModernDesignSystem.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(ModernDesignSystem.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .stroke(ModernDesignSystem.Colors.primary, lineWidth: 2)
            )
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
        }
    }
}

struct ModernCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = ModernDesignSystem.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(ModernDesignSystem.Colors.card)
            .cornerRadius(ModernDesignSystem.CornerRadius.lg)
            .shadow(color: ModernDesignSystem.Shadows.medium.color, radius: ModernDesignSystem.Shadows.medium.radius, x: ModernDesignSystem.Shadows.medium.x, y: ModernDesignSystem.Shadows.medium.y)
    }
}

struct ModernTextField: View {
    let placeholder: String
    let icon: String?
    @Binding var text: String
    let keyboardType: UIKeyboardType
    
    init(_ placeholder: String, icon: String? = nil, text: Binding<String>, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.textSecondary)
                    .frame(width: 20)
            }
            
            TextField(placeholder, text: $text)
                .font(ModernDesignSystem.Typography.bodyMedium)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(ModernDesignSystem.Colors.surface)
        .cornerRadius(ModernDesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(ModernDesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

struct ModernStatusBadge: View {
    let title: String
    let type: StatusType
    
    enum StatusType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return ModernDesignSystem.Colors.success
            case .warning: return ModernDesignSystem.Colors.warning
            case .error: return ModernDesignSystem.Colors.error
            case .info: return ModernDesignSystem.Colors.info
            }
        }
    }
    
    var body: some View {
        Text(title)
            .font(ModernDesignSystem.Typography.labelSmall)
            .fontWeight(.semibold)
            .foregroundColor(type.color)
            .padding(.horizontal, ModernDesignSystem.Spacing.sm)
            .padding(.vertical, ModernDesignSystem.Spacing.xs)
            .background(type.color.opacity(0.1))
            .cornerRadius(ModernDesignSystem.CornerRadius.full)
    }
}

// MARK: - Extensions
extension View {
    func modernShadow(_ shadow: ModernDesignSystem.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func modernCard() -> some View {
        ModernCard {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: ModernDesignSystem.Spacing.lg) {
        ModernPrimaryButton("Start New Session", icon: "plus.circle") {
            print("Primary button tapped")
        }
        
        ModernSecondaryButton("View Projects", icon: "folder") {
            print("Secondary button tapped")
        }
        
        ModernCard {
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
                Text("Project Information")
                    .font(ModernDesignSystem.Typography.titleMedium)
                    .foregroundColor(ModernDesignSystem.Colors.text)
                
                ModernTextField("Project Name", icon: "pencil", text: .constant(""))
                
                HStack {
                    ModernStatusBadge("Active", type: .success)
                    ModernStatusBadge("3 Sessions", type: .info)
                }
            }
        }
    }
    .padding()
    .background(ModernDesignSystem.Colors.background)
}
