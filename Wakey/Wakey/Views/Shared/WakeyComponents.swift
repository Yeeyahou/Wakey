import SwiftUI

struct WakeyChip: View {
    let text: String
    var color: Color = WakeyColors.primary
    var isSelected = true

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isSelected ? color : WakeyColors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color.opacity(0.20) : WakeyColors.cardBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.black.opacity(0.07), lineWidth: 1))
    }
}

struct GradientButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(LinearGradient.wakeyButton)
            .clipShape(Capsule())
            .shadow(color: WakeyColors.primary.opacity(0.25), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct IconCircleButton: View {
    let systemName: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(WakeyColors.primary)
                .frame(width: 54, height: 54)
                .background(WakeyColors.primary.opacity(0.10))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    var iconColor: Color = WakeyColors.accent
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.system(size: 16))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(WakeyColors.primary)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
                .frame(width: 80, height: 80)
                .background(Color.black.opacity(0.04))
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(WakeyColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}
