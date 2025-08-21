import Foundation

// MARK: - Fraction Utilities

struct FractionUtils {
    
    /// Parse a fractional inch string to decimal inches
    /// - Parameter input: String like "1 3/8", "3/4", "2.5", etc.
    /// - Returns: Decimal value in inches, or nil if parsing fails
    static func parseFractionalInches(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle decimal format
        if let decimal = Double(trimmed) {
            return decimal
        }
        
        // Handle mixed number format (e.g., "1 3/8")
        let components = trimmed.components(separatedBy: .whitespaces)
        
        if components.count == 2 {
            // Mixed number: whole number + fraction
            guard let wholeNumber = Double(components[0]),
                  let fraction = parseFraction(components[1]) else {
                return nil
            }
            return wholeNumber + fraction
        } else if components.count == 1 {
            // Single fraction or whole number
            return parseFraction(components[0]) ?? Double(components[0])
        }
        
        return nil
    }
    
    /// Parse a fraction string to decimal
    /// - Parameter input: String like "3/8", "1/2", etc.
    /// - Returns: Decimal value, or nil if parsing fails
    private static func parseFraction(_ input: String) -> Double? {
        let components = input.components(separatedBy: "/")
        
        guard components.count == 2,
              let numerator = Double(components[0]),
              let denominator = Double(components[1]),
              denominator != 0 else {
            return nil
        }
        
        return numerator / denominator
    }
    
    /// Format decimal inches to fractional string
    /// - Parameters:
    ///   - value: Decimal value in inches
    ///   - resolution: Fractional resolution (.eighth or .sixteenth)
    /// - Returns: Formatted string like "1 3/8" or "2.5"
    static func formatFractionalInches(_ value: Double, resolution: FractionalResolution) -> String {
        // Round to the nearest fraction
        let roundedValue = roundToFraction(value, resolution: resolution)
        
        // Extract whole number and fractional part
        let wholeNumber = Int(roundedValue)
        let fractionalPart = roundedValue - Double(wholeNumber)
        
        // Convert fractional part to fraction
        let fraction = decimalToFraction(fractionalPart, resolution: resolution)
        
        // Format the result
        if wholeNumber == 0 {
            if fractionalPart == 0 {
                return "0"
            } else {
                return fraction
            }
        } else {
            if fractionalPart == 0 {
                return "\(wholeNumber)"
            } else {
                return "\(wholeNumber) \(fraction)"
            }
        }
    }
    
    /// Round a decimal value to the nearest fraction
    /// - Parameters:
    ///   - value: Decimal value
    ///   - resolution: Fractional resolution
    /// - Returns: Rounded value
    private static func roundToFraction(_ value: Double, resolution: FractionalResolution) -> Double {
        let fractionValue = resolution.decimalValue
        return round(value / fractionValue) * fractionValue
    }
    
    /// Convert decimal to fraction string
    /// - Parameters:
    ///   - decimal: Decimal value between 0 and 1
    ///   - resolution: Fractional resolution
    /// - Returns: Fraction string like "3/8"
    private static func decimalToFraction(_ decimal: Double, resolution: FractionalResolution) -> String {
        let tolerance = resolution.decimalValue / 2.0
        
        // Common fractions for better readability
        let commonFractions: [(numerator: Int, denominator: Int)] = [
            (1, 2),   // 1/2
            (1, 4),   // 1/4
            (3, 4),   // 3/4
            (1, 8),   // 1/8
            (3, 8),   // 3/8
            (5, 8),   // 5/8
            (7, 8),   // 7/8
            (1, 16),  // 1/16
            (3, 16),  // 3/16
            (5, 16),  // 5/16
            (7, 16),  // 7/16
            (9, 16),  // 9/16
            (11, 16), // 11/16
            (13, 16), // 13/16
            (15, 16)  // 15/16
        ]
        
        // Check common fractions first
        for fraction in commonFractions {
            let fractionValue = Double(fraction.numerator) / Double(fraction.denominator)
            if abs(decimal - fractionValue) < tolerance {
                return "\(fraction.numerator)/\(fraction.denominator)"
            }
        }
        
        // If no common fraction matches, use the resolution-based approach
        let steps = Int(round(decimal / resolution.decimalValue))
        let numerator = steps
        let denominator = Int(1.0 / resolution.decimalValue)
        
        return "\(numerator)/\(denominator)"
    }
    
    /// Convert inches to millimeters
    /// - Parameter inches: Value in inches
    /// - Returns: Value in millimeters
    static func inchesToMM(_ inches: Double) -> Double {
        return inches * 25.4
    }
    
    /// Convert millimeters to inches
    /// - Parameter mm: Value in millimeters
    /// - Returns: Value in inches
    static func mmToInches(_ mm: Double) -> Double {
        return mm / 25.4
    }
    
    /// Format a measurement value with appropriate units
    /// - Parameters:
    ///   - value: Measurement value
    ///   - units: Units to format for
    ///   - resolution: Fractional resolution (for imperial)
    /// - Returns: Formatted string with units
    static func formatMeasurement(_ value: Double, units: SessionUnits, resolution: FractionalResolution? = nil) -> String {
        switch units {
        case .imperial:
            if let resolution = resolution {
                let formatted = formatFractionalInches(value, resolution: resolution)
                return "\(formatted) in"
            } else {
                return String(format: "%.3f in", value)
            }
        case .metric:
            return String(format: "%.1f mm", value)
        }
    }
    
    /// Validate if a string represents a valid measurement
    /// - Parameters:
    ///   - input: Input string
    ///   - units: Expected units
    /// - Returns: True if valid, false otherwise
    static func isValidMeasurement(_ input: String, units: SessionUnits) -> Bool {
        switch units {
        case .imperial:
            return parseFractionalInches(input) != nil
        case .metric:
            return Double(input) != nil
        }
    }
    
    /// Get the display precision for a given resolution
    /// - Parameter resolution: Fractional resolution
    /// - Returns: Number of decimal places
    static func displayPrecision(for resolution: FractionalResolution) -> Int {
        switch resolution {
        case .eighth:
            return 3 // 0.125
        case .sixteenth:
            return 4 // 0.0625
        }
    }
    
    /// Convert a measurement from one unit system to another
    /// - Parameters:
    ///   - value: Original value
    ///   - fromUnits: Source units
    ///   - toUnits: Target units
    ///   - resolution: Fractional resolution (for imperial output)
    /// - Returns: Converted and formatted value
    static func convertAndFormat(_ value: Double, from fromUnits: SessionUnits, to toUnits: SessionUnits, resolution: FractionalResolution? = nil) -> String {
        let convertedValue: Double
        
        switch (fromUnits, toUnits) {
        case (.imperial, .metric):
            convertedValue = inchesToMM(value)
        case (.metric, .imperial):
            convertedValue = mmToInches(value)
        default:
            convertedValue = value
        }
        
        return formatMeasurement(convertedValue, units: toUnits, resolution: resolution)
    }
}
