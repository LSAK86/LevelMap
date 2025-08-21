import SwiftUI

struct GridSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var rows: Int
    @Binding var cols: Int
    let onApply: () -> Void
    
    @State private var selectedPreset: GridPreset?
    @State private var customRows: Int
    @State private var customCols: Int
    @State private var showingCustomInput = false
    
    init(rows: Binding<Int>, cols: Binding<Int>, onApply: @escaping () -> Void) {
        self._rows = rows
        self._cols = cols
        self.onApply = onApply
        self._customRows = State(initialValue: rows.wrappedValue)
        self._customCols = State(initialValue: cols.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Preset options
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Grid Presets")
                        .font(DesignSystem.Typography.sectionTitle)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.md) {
                        ForEach(GridPreset.allCases, id: \.self) { preset in
                            GridPresetCard(
                                preset: preset,
                                isSelected: selectedPreset == preset,
                                onTap: {
                                    selectedPreset = preset
                                    customRows = preset.rows
                                    customCols = preset.cols
                                    showingCustomInput = false
                                }
                            )
                        }
                    }
                }
                
                // Custom grid option
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("Custom Grid")
                            .font(DesignSystem.Typography.sectionTitle)
                        
                        Spacer()
                        
                        Button("Custom") {
                            showingCustomInput = true
                            selectedPreset = nil
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    if showingCustomInput {
                        CustomGridInputView(
                            rows: $customRows,
                            cols: $customCols
                        )
                    }
                }
                
                // Preview
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Preview")
                        .font(DesignSystem.Typography.sectionTitle)
                    
                    GridPreviewView(rows: customRows, cols: customCols)
                        .frame(height: 200)
                }
                
                Spacer()
                
                // Apply button
                PrimaryButton("Apply Grid Settings") {
                    rows = customRows
                    cols = customCols
                    onApply()
                    dismiss()
                }
            }
            .padding()
            .navigationTitle("Grid Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Set initial custom values
            customRows = rows
            customCols = cols
        }
    }
}

// MARK: - Grid Preset

enum GridPreset: CaseIterable {
    case halves
    case fourths
    case eighths
    case sixteenths
    case custom
    
    var name: String {
        switch self {
        case .halves: return "Halves"
        case .fourths: return "Fourths"
        case .eighths: return "Eighths"
        case .sixteenths: return "Sixteenths"
        case .custom: return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .halves: return "2 × 2 grid"
        case .fourths: return "4 × 4 grid"
        case .eighths: return "8 × 8 grid"
        case .sixteenths: return "16 × 16 grid"
        case .custom: return "Custom dimensions"
        }
    }
    
    var rows: Int {
        switch self {
        case .halves: return 2
        case .fourths: return 4
        case .eighths: return 8
        case .sixteenths: return 16
        case .custom: return 4
        }
    }
    
    var cols: Int {
        switch self {
        case .halves: return 2
        case .fourths: return 4
        case .eighths: return 8
        case .sixteenths: return 16
        case .custom: return 4
        }
    }
    
    var icon: String {
        switch self {
        case .halves: return "square.grid.2x2"
        case .fourths: return "square.grid.4x4"
        case .eighths: return "square.grid.8x8"
        case .sixteenths: return "square.grid.16x16"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Grid Preset Card

struct GridPresetCard: View {
    let preset: GridPreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: preset.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.primary)
                
                Text(preset.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.text)
                
                Text(preset.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Grid Input View

struct CustomGridInputView: View {
    @Binding var rows: Int
    @Binding var cols: Int
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Rows")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Stepper("\(rows)", value: $rows, in: 2...26)
                        .font(DesignSystem.Typography.body)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Columns")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Stepper("\(cols)", value: $cols, in: 2...50)
                        .font(DesignSystem.Typography.body)
                }
            }
            
            // Validation message
            if !GeometryUtils.validateGridDimensions(rows: rows, cols: cols) {
                Text("Grid dimensions must be between 2×2 and 26×50")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
    }
}

// MARK: - Grid Preview View

struct GridPreviewView: View {
    let rows: Int
    let cols: Int
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width / CGFloat(cols),
                geometry.size.height / CGFloat(rows)
            )
            
            VStack(spacing: 1) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(0..<cols, id: \.self) { col in
                            Rectangle()
                                .fill(cellColor(for: row, col: col))
                                .frame(width: cellSize, height: cellSize)
                                .overlay(
                                    Text("\(rowLetter(row))\(col + 1)")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
            .frame(
                width: cellSize * CGFloat(cols),
                height: cellSize * CGFloat(rows)
            )
            .background(Color.gray.opacity(0.2))
            .cornerRadius(DesignSystem.CornerRadius.sm)
        }
    }
    
    private func cellColor(for row: Int, col: Int) -> Color {
        let isCorner = (row == 0 || row == rows - 1) && (col == 0 || col == cols - 1)
        let isEdge = row == 0 || row == rows - 1 || col == 0 || col == cols - 1
        
        if isCorner {
            return DesignSystem.Colors.primary
        } else if isEdge {
            return DesignSystem.Colors.primary.opacity(0.7)
        } else {
            return DesignSystem.Colors.primary.opacity(0.3)
        }
    }
    
    private func rowLetter(_ row: Int) -> String {
        return String(Character(UnicodeScalar(65 + row)!))
    }
}

#Preview {
    GridSettingsView(
        rows: .constant(4),
        cols: .constant(4)
    ) {
        print("Grid settings applied")
    }
}
