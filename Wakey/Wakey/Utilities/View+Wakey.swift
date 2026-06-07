import SwiftUI

extension View {
    func wakeyCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(WakeyColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    func wakeyScreenBackground() -> some View {
        self
            .background(WakeyColors.background.ignoresSafeArea())
            .foregroundStyle(WakeyColors.textPrimary)
    }
}
