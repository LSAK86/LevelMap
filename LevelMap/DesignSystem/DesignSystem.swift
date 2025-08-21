import SwiftUI

// MARK: - Design System

struct DesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary colors
        static let primary = Color("PrimaryColor", bundle: nil) ?? Color.blue
        static let primaryDark = Color("PrimaryDarkColor", bundle: nil) ?? Color.blue.opacity(0.8)
        static let primaryLight = Color("PrimaryLightColor", bundle: nil) ?? Color.blue.opacity(0.2)
        
        // Secondary colors
        static let secondary = Color("SecondaryColor", bundle: nil) ?? Color.orange
        static let secondaryDark = Color("SecondaryDarkColor", bundle: nil) ?? Color.orange.opacity(0.8)
        static let secondaryLight = Color("SecondaryLightColor", bundle: nil) ?? Color.orange.opacity(0.2)
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Neutral colors
        static let background = Color("BackgroundColor", bundle: nil) ?? Color(.systemBackground)
        static let secondaryBackground = Color("SecondaryBackgroundColor", bundle: nil) ?? Color(.secondarySystemBackground)
        static let tertiaryBackground = Color("TertiaryBackgroundColor", bundle: nil) ?? Color(.tertiarySystemBackground)
        
        static let text = Color("TextColor", bundle: nil) ?? Color(.label)
        static let secondaryText = Color("SecondaryTextColor", bundle: nil) ?? Color(.secondaryLabel)
        static let tertiaryText = Color("TertiaryTextColor", bundle: nil) ?? Color(.tertiaryLabel)
        
        // AR overlay colors
        static let arOverlay = Color.black.opacity(0.6)
        static let arText = Color.white
        static let arAccent = Color.blue
        static let arSuccess = Color.green
        static let arWarning = Color.orange
        static let arError = Color.red
        
        // Heatmap colors
        static let heatmapGreen = Color.green
        static let heatmapYellow = Color.yellow
        static let heatmapRed = Color.red
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Font sizes
        static let largeTitle = Font.largeTitle
        static let title1 = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
        
        // Font weights
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        static let heavy = Font.Weight.heavy
        
        // Custom text styles
        static let sectionTitle = Font.title2.weight(.semibold)
        static let cardTitle = Font.headline.weight(.medium)
        static let buttonText = Font.body.weight(.semibold)
        static let caption = Font.caption.weight(.medium)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Common spacing combinations
        static let cardPadding = EdgeInsets(top: md, leading: md, bottom: md, trailing: md)
        static let listPadding = EdgeInsets(top: sm, leading: md, bottom: sm, trailing: md)
        static let buttonPadding = EdgeInsets(top: sm, leading: lg, bottom: sm, trailing: lg)
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
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Reusable Components

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.buttonText)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.buttonPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(backgroundColor)
            )
        }
        .disabled(isLoading || isDisabled)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return DesignSystem.Colors.secondaryText
        }
        return DesignSystem.Colors.primary
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    init(_ title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.buttonText)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.buttonPadding)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(foregroundColor, lineWidth: 1)
                )
        }
        .disabled(isDisabled)
    }
    
    private var foregroundColor: Color {
        isDisabled ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primary
    }
}

// MARK: - Card View

struct CardView<Content: View>: View {
    let content: Content
    let padding: EdgeInsets
    let backgroundColor: Color
    let shadow: DesignSystem.Shadow?
    
    init(
        padding: EdgeInsets = DesignSystem.Spacing.cardPadding,
        backgroundColor: Color = DesignSystem.Colors.background,
        shadow: DesignSystem.Shadow? = DesignSystem.Shadows.small,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.shadow = shadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(backgroundColor)
            )
            .shadow(
                color: shadow?.color ?? .clear,
                radius: shadow?.radius ?? 0,
                x: shadow?.x ?? 0,
                y: shadow?.y ?? 0
            )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.sectionTitle)
                    .foregroundColor(DesignSystem.Colors.text)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.text)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(
        title: String = "Error",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.error)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(message)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                PrimaryButton("Retry", action: retryAction)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: Status
    let size: BadgeSize
    
    enum Status {
        case success
        case warning
        case error
        case info
        case neutral
        
        var color: Color {
            switch self {
            case .success: return DesignSystem.Colors.success
            case .warning: return DesignSystem.Colors.warning
            case .error: return DesignSystem.Colors.error
            case .info: return DesignSystem.Colors.info
            case .neutral: return DesignSystem.Colors.secondaryText
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .success: return DesignSystem.Colors.success.opacity(0.1)
            case .warning: return DesignSystem.Colors.warning.opacity(0.1)
            case .error: return DesignSystem.Colors.error.opacity(0.1)
            case .info: return DesignSystem.Colors.info.opacity(0.1)
            case .neutral: return DesignSystem.Colors.secondaryText.opacity(0.1)
            }
        }
    }
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return DesignSystem.Typography.caption2
            case .medium: return DesignSystem.Typography.caption
            case .large: return DesignSystem.Typography.footnote
            }
        }
    }
    
    init(_ status: Status, size: BadgeSize = .medium) {
        self.status = status
        self.size = size
    }
    
    var body: some View {
        Text(statusText)
            .font(size.fontSize)
            .foregroundColor(status.color)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.full)
                    .fill(status.backgroundColor)
            )
    }
    
    private var statusText: String {
        switch status {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        case .info: return "Info"
        case .neutral: return "Neutral"
        }
    }
}

// MARK: - AR Overlay Components

// MARK: - AR Button

struct ARButton: View {
    let title: String
    let action: () -> Void
    let isActive: Bool
    let isDisabled: Bool
    
    init(
        _ title: String,
        isActive: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isActive = isActive
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.buttonText)
                .foregroundColor(DesignSystem.Colors.arText)
                .padding(DesignSystem.Spacing.buttonPadding)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(backgroundColor)
                )
        }
        .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return DesignSystem.Colors.arOverlay
        }
        return isActive ? DesignSystem.Colors.arSuccess : DesignSystem.Colors.arAccent
    }
}

// MARK: - AR Info Panel

struct ARInfoPanel: View {
    let title: String
    let value: String
    let unit: String?
    
    init(_ title: String, value: String, unit: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.arText)
            
            HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
                Text(value)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.arText)
                
                if let unit = unit {
                    Text(unit)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.arText.opacity(0.8))
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.arOverlay)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        PrimaryButton("Primary Action", isLoading: false) {
            print("Primary button tapped")
        }
        
        SecondaryButton("Secondary Action") {
            print("Secondary button tapped")
        }
        
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Card Title")
                    .font(DesignSystem.Typography.cardTitle)
                Text("Card content goes here")
                    .font(DesignSystem.Typography.body)
            }
        }
        
        SectionHeader("Section Title", subtitle: "Section description")
        
        HStack {
            StatusBadge(.success)
            StatusBadge(.warning)
            StatusBadge(.error)
            StatusBadge(.info)
        }
        
        ARButton("AR Action", isActive: true) {
            print("AR button tapped")
        }
        
        ARInfoPanel("Distance", value: "12.5", unit: "ft")
    }
    .padding()
}
