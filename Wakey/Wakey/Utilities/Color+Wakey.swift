import SwiftUI

struct WakeyColors {
    static let primary = Color(hex: "FF9A7F")
    static let accent = Color(hex: "A8D8EA")
    static let secondary = Color(hex: "FFE5B4")
    static let background = Color(hex: "FFFBF5")
    static let cardBackground = Color.white
    static let textPrimary = Color(hex: "2D2D2D")
    static let textSecondary = Color(hex: "8B8B8B")
    static let destructive = Color(hex: "FF6B6B")
    static let success = Color(hex: "4CAF50")
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension LinearGradient {
    static let wakeyButton = LinearGradient(
        colors: [WakeyColors.primary, WakeyColors.accent],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let wakeySoft = LinearGradient(
        colors: [WakeyColors.primary.opacity(0.10), WakeyColors.accent.opacity(0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
