import SwiftUI

// MARK: - Warm Modern Color Palette with Dark Mode Support
extension Color {
    // Primary accent colors - adaptive for dark mode
    static let warmOrange = Color(.displayP3, red: 0.95, green: 0.6, blue: 0.2)
    static let warmAmber = Color(.displayP3, red: 0.98, green: 0.7, blue: 0.3)
    static let warmRed = Color(.displayP3, red: 0.9, green: 0.3, blue: 0.2)
    static let warmGreen = Color(.displayP3, red: 0.4, green: 0.7, blue: 0.3)
    static let warmBlue = Color(.displayP3, red: 0.3, green: 0.5, blue: 0.8)
    
    // Adaptive backgrounds
    static let backgroundPrimary = Color(
        light: Color(.displayP3, red: 0.99, green: 0.98, blue: 0.96),
        dark: Color(.displayP3, red: 0.11, green: 0.11, blue: 0.12)
    )
    
    static let backgroundSecondary = Color(
        light: Color(.displayP3, red: 0.97, green: 0.95, blue: 0.92),
        dark: Color(.displayP3, red: 0.15, green: 0.15, blue: 0.16)
    )
    
    static let cardBackground = Color(
        light: Color.white,
        dark: Color(.displayP3, red: 0.19, green: 0.19, blue: 0.20)
    )
    
    // Adaptive text colors
    static let textPrimary = Color(
        light: Color(.displayP3, red: 0.2, green: 0.2, blue: 0.2),
        dark: Color(.displayP3, red: 0.95, green: 0.95, blue: 0.95)
    )
    
    static let textSecondary = Color(
        light: Color(.displayP3, red: 0.5, green: 0.5, blue: 0.5),
        dark: Color(.displayP3, red: 0.7, green: 0.7, blue: 0.7)
    )
    
    static let textAccent = Color(
        light: Color(.displayP3, red: 0.6, green: 0.4, blue: 0.2),
        dark: Color(.displayP3, red: 0.92, green: 0.7, blue: 0.4)
    )
    
    // Okami theme colors - adaptive
    static let okamiGold = Color(
        light: Color(.displayP3, red: 0.92, green: 0.7, blue: 0.15),
        dark: Color(.displayP3, red: 1.0, green: 0.8, blue: 0.3)
    )
    
    static let okamiRed = Color(
        light: Color(.displayP3, red: 0.85, green: 0.2, blue: 0.1),
        dark: Color(.displayP3, red: 0.95, green: 0.4, blue: 0.3)
    )
    
    static let okamiEarth = Color(
        light: Color(.displayP3, red: 0.45, green: 0.25, blue: 0.1),
        dark: Color(.displayP3, red: 0.6, green: 0.4, blue: 0.25)
    )
    
    static let okamiParchment = Color(
        light: Color(.displayP3, red: 0.98, green: 0.96, blue: 0.92),
        dark: Color(.displayP3, red: 0.12, green: 0.12, blue: 0.13)
    )
    
    static let okamiAmber = Color(
        light: Color(.displayP3, red: 0.95, green: 0.75, blue: 0.2),
        dark: Color(.displayP3, red: 1.0, green: 0.85, blue: 0.4)
    )
    
    // Button text that works on colored backgrounds
    static let buttonTextOnColor = Color.white
    
    // Text for buttons on adaptive backgrounds
    static let buttonText = Color(
        light: Color.white,
        dark: Color(.displayP3, red: 0.95, green: 0.95, blue: 0.95)
    )
}

// MARK: - Dark Mode Color Helper
extension Color {
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}