import SwiftUI

struct ToleranceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var tolerance: Double
    @Binding var units: SessionUnits
    
    @State private var selectedPreset: TolerancePreset?
    @State private var customTolerance: Double
    @State private var customUnits: SessionUnits
    @State private var showingCustomInput = false
    
    init(tolerance: Binding<Double>, units: Binding<SessionUnits>) {
        self._tolerance = tolerance
        self._units = units
        self._customTolerance = State(initialValue: tolerance.wrappedValue)
        self._customUnits = State(initialValue: units.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Units selection
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Measurement Units")
                        .font(DesignSystem.Typography.sectionTitle)
                    
                    Picker("Units", selection: $customUnits) {
                        ForEach(SessionUnits.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: customUnits) { newUnits in
                        // Convert tolerance value when units change
                        customTolerance = convertTolerance(tolerance, from: units, to: newUnits)
                    }
                }
                
                // Tolerance presets
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Tolerance Presets")
                        .font(DesignSystem.Typography.sectionTitle)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.md) {
                        ForEach(TolerancePreset.presets(for: customUnits), id: \.self) { preset in
                            TolerancePresetCard(
                                preset: preset,
                                isSelected: selectedPreset == preset,
                                onTap: {
                                    selectedPreset = preset
                                    customTolerance = preset.value
                                    showingCustomInput = false
                                }
                            )
                        }
                    }
                }
                
                // Custom tolerance option
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("Custom Tolerance")
                            .font(DesignSystem.Typography.sectionTitle)
                        
                        Spacer()
                        
                        Button("Custom") {
                            showingCustomInput = true
                            selectedPreset = nil
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    if showingCustomInput {
                        CustomToleranceInputView(
                            tolerance: $customTolerance,
                            units: $customUnits
                        )
                    }
                }
                
                // Tolerance preview
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Current Tolerance")
                        .font(DesignSystem.Typography.sectionTitle)
                    
                    HStack {
                        Text(formatMeasurement(customTolerance, units: customUnits))
                            .font(DesignSystem.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                            Text("± \(formatMeasurement(customTolerance, units: customUnits))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("Range: \(formatMeasurement(-customTolerance, units: customUnits)) to \(formatMeasurement(customTolerance, units: customUnits))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .fill(DesignSystem.Colors.secondaryBackground)
                    )
                }
                
                Spacer()
                
                // Apply button
                PrimaryButton("Apply Tolerance Settings") {
                    tolerance = customTolerance
                    units = customUnits
                    dismiss()
                }
            }
            .padding()
            .navigationTitle("Tolerance Settings")
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
            customTolerance = tolerance
            customUnits = units
        }
    }
    
    private func convertTolerance(_ value: Double, from fromUnits: SessionUnits, to toUnits: SessionUnits) -> Double {
        if fromUnits == toUnits {
            return value
        }
        
        switch (fromUnits, toUnits) {
        case (.imperial, .metric):
            return FractionUtils.inchesToMM(value)
        case (.metric, .imperial):
            return FractionUtils.mmToInches(value)
        default:
            return value
        }
    }
}

// MARK: - Tolerance Preset

struct TolerancePreset: Hashable {
    let name: String
    let value: Double
    let description: String
    let category: PresetCategory
    
    enum PresetCategory: String, CaseIterable {
        case tight = "Tight"
        case standard = "Standard"
        case loose = "Loose"
        case custom = "Custom"
        
        var color: Color {
            switch self {
            case .tight: return DesignSystem.Colors.success
            case .standard: return DesignSystem.Colors.primary
            case .loose: return DesignSystem.Colors.warning
            case .custom: return DesignSystem.Colors.secondary
            }
        }
    }
    
    static func presets(for units: SessionUnits) -> [TolerancePreset] {
        switch units {
        case .imperial:
            return [
                TolerancePreset(name: "1/16\"", value: 1.0/16.0, description: "Very tight", category: .tight),
                TolerancePreset(name: "1/8\"", value: 1.0/8.0, description: "Tight", category: .tight),
                TolerancePreset(name: "1/4\"", value: 1.0/4.0, description: "Standard", category: .standard),
                TolerancePreset(name: "1/2\"", value: 1.0/2.0, description: "Loose", category: .loose),
                TolerancePreset(name: "1\"", value: 1.0, description: "Very loose", category: .loose)
            ]
        case .metric:
            return [
                TolerancePreset(name: "1 mm", value: 1.0, description: "Very tight", category: .tight),
                TolerancePreset(name: "2 mm", value: 2.0, description: "Tight", category: .tight),
                TolerancePreset(name: "5 mm", value: 5.0, description: "Standard", category: .standard),
                TolerancePreset(name: "10 mm", value: 10.0, description: "Loose", category: .loose),
                TolerancePreset(name: "20 mm", value: 20.0, description: "Very loose", category: .loose)
            ]
        }
    }
}

// MARK: - Tolerance Preset Card

struct TolerancePresetCard: View {
    let preset: TolerancePreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(preset.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.text)
                
                Text(preset.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DesignSystem.Colors.secondaryText)
                
                Text("± \(formatMeasurement(preset.value, units: .imperial))")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : preset.category.color)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? preset.category.color : DesignSystem.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isSelected ? preset.category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Tolerance Input View

struct CustomToleranceInputView: View {
    @Binding var tolerance: Double
    @Binding var units: SessionUnits
    
    @State private var toleranceString: String = ""
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Tolerance Value")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    TextField("Enter tolerance", text: $toleranceString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .onChange(of: toleranceString) { newValue in
                            if let value = Double(newValue) {
                                tolerance = value
                            }
                        }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Units")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Picker("Units", selection: $units) {
                        ForEach(SessionUnits.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Validation message
            if !ToleranceEngine.validateTolerance(tolerance, units: units) {
                Text("Tolerance must be positive and reasonable for the selected units")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.error)
            }
            
            // Quick adjustment buttons
            HStack {
                Text("Quick Adjust:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                ForEach(quickAdjustValues, id: \.self) { value in
                    Button(formatMeasurement(value, units: units)) {
                        tolerance = value
                        toleranceString = String(format: "%.2f", value)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
        .onAppear {
            toleranceString = String(format: "%.2f", tolerance)
        }
    }
    
    private var quickAdjustValues: [Double] {
        switch units {
        case .imperial:
            return [0.125, 0.25, 0.5, 1.0] // 1/8", 1/4", 1/2", 1"
        case .metric:
            return [2.0, 5.0, 10.0, 20.0] // 2mm, 5mm, 10mm, 20mm
        }
    }
}

// MARK: - Tolerance Info View

struct ToleranceInfoView: View {
    let tolerance: Double
    let units: SessionUnits
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Tolerance Information")
                .font(DesignSystem.Typography.sectionTitle)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("Acceptable Range:")
                    Spacer()
                    Text("± \(formatMeasurement(tolerance, units: units))")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Min Value:")
                    Spacer()
                    Text("-\(formatMeasurement(tolerance, units: units))")
                        .foregroundColor(DesignSystem.Colors.error)
                }
                
                HStack {
                    Text("Max Value:")
                    Spacer()
                    Text("+\(formatMeasurement(tolerance, units: units))")
                        .foregroundColor(DesignSystem.Colors.success)
                }
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

#Preview {
    ToleranceSettingsView(
        tolerance: .constant(0.25),
        units: .constant(.imperial)
    )
}
