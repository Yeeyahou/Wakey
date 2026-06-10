import SwiftUI
import UIKit

struct WakeyOKLCH {
    let lightness: Double
    let chroma: Double
    let hue: Double
    let alpha: Double

    init(_ lightness: Double, _ chroma: Double, _ hue: Double, alpha: Double = 1) {
        self.lightness = lightness
        self.chroma = chroma
        self.hue = hue
        self.alpha = alpha
    }

    var color: Color {
        Color(uiColor: uiColor)
    }

    var uiColor: UIColor {
        let radians = hue * .pi / 180
        let a = chroma * cos(radians)
        let b = chroma * sin(radians)

        let lPrime = lightness + 0.3963377774 * a + 0.2158037573 * b
        let mPrime = lightness - 0.1055613458 * a - 0.0638541728 * b
        let sPrime = lightness - 0.0894841775 * a - 1.2914855480 * b

        let l = lPrime * lPrime * lPrime
        let m = mPrime * mPrime * mPrime
        let s = sPrime * sPrime * sPrime

        let redLinear = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let greenLinear = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let blueLinear = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        return UIColor(
            red: CGFloat(Self.encodeSRGB(redLinear)),
            green: CGFloat(Self.encodeSRGB(greenLinear)),
            blue: CGFloat(Self.encodeSRGB(blueLinear)),
            alpha: CGFloat(alpha.clamped(to: 0...1))
        )
    }

    private static func encodeSRGB(_ value: Double) -> Double {
        let clamped = value.clamped(to: 0...1)
        if clamped <= 0.0031308 {
            return 12.92 * clamped
        }
        return 1.055 * pow(clamped, 1 / 2.4) - 0.055
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct WakeyGradientColors {
    static let primary = WakeyOKLCH(0.78, 0.145, 35)
    static let buttonEnd = WakeyOKLCH(0.86, 0.105, 58)
    static let accent = WakeyOKLCH(0.84, 0.075, 220)
    static let secondary = WakeyOKLCH(0.92, 0.080, 82)
    static let background = WakeyOKLCH(0.985, 0.012, 78)
    static let destructive = WakeyOKLCH(0.68, 0.190, 28)
    static let success = WakeyOKLCH(0.67, 0.160, 145)
}

enum WakeyProfile {
    static let nicknameKey = "wakey.profile.nickname"
    static let defaultNickname = "정원"

    static var nickname: String {
        get {
            let stored = UserDefaults.standard.string(forKey: nicknameKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let stored, !stored.isEmpty, stored != "지우" else {
                return defaultNickname
            }
            return stored
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed.isEmpty ? defaultNickname : trimmed, forKey: nicknameKey)
        }
    }
}

struct WakeyColors {
    static let primary = WakeyGradientColors.primary.color
    static let accent = WakeyGradientColors.accent.color
    static let secondary = WakeyGradientColors.secondary.color
    static let background = WakeyGradientColors.background.color
    static let cardBackground = Color.white
    static let textPrimary = Color(hex: "2D2D2D")
    static let textSecondary = Color(hex: "8B8B8B")
    static let destructive = WakeyGradientColors.destructive.color
    static let success = WakeyGradientColors.success.color
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
        colors: [WakeyGradientColors.primary.color, WakeyGradientColors.buttonEnd.color],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let wakeySoft = LinearGradient(
        colors: [WakeyGradientColors.primary.color.opacity(0.10), WakeyGradientColors.accent.color.opacity(0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
