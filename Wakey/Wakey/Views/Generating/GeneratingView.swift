import SwiftUI

struct GeneratingView: View {
    @EnvironmentObject private var weatherService: WeatherService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var notificationService: NotificationManager
    let draft: AlarmDraft
    let onComplete: (AlarmSong) -> Void

    @State private var isAnimating = false
    @StateObject private var viewModel = GeneratingViewModel()

    var body: some View {
        VStack(spacing: 34) {
            Spacer()
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkles")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(WakeyColors.accent)
                        .scaleEffect(isAnimating ? 1 : 0.2)
                        .opacity(isAnimating ? 0.15 : 1)
                        .offset(x: cos(CGFloat(index) * .pi / 3) * 105, y: sin(CGFloat(index) * .pi / 3) * 80)
                        .animation(.easeInOut(duration: 1.6).repeatForever().delay(Double(index) * 0.18), value: isAnimating)
                }
                Image(systemName: "music.note")
                    .font(.system(size: 66, weight: .medium))
                    .foregroundStyle(WakeyColors.primary)
                    .frame(width: 150, height: 150)
                    .background(LinearGradient.wakeySoft)
                    .clipShape(Circle())
                    .offset(y: isAnimating ? -18 : 12)
                    .rotationEffect(.degrees(isAnimating ? 8 : -8))
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isAnimating)
            }
            .frame(height: 180)

            VStack(spacing: 12) {
                Text(viewModel.phase == .completed ? "알람송 준비 완료" : "알람송을 만드는 중이에요")
                    .font(.system(size: 26, weight: .semibold))
                Text(viewModel.phase.message)
                    .font(.system(size: 16))
                    .foregroundStyle(WakeyColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 14) {
                HStack {
                    WakeyChip(text: draft.mood.rawValue, color: WakeyColors.accent)
                    WakeyChip(text: draft.purpose.rawValue, color: WakeyColors.secondary)
                }
                Text("\"\(draft.memo)\"")
                    .font(.system(size: 14))
                    .foregroundStyle(WakeyColors.textSecondary)
                    .lineLimit(2)
                if let statusDetail = viewModel.statusDetail {
                    Text(statusDetail)
                        .font(.system(size: 13))
                        .foregroundStyle(WakeyColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .wakeyCard(cornerRadius: 24)
            .padding(.horizontal, 28)

            ProgressView()
                .tint(WakeyColors.primary)
                .padding(.horizontal, 42)
            Spacer()
        }
        .wakeyScreenBackground()
        .task {
            isAnimating = true
            let alarm = await viewModel.generate(
                draft: draft,
                weatherService: weatherService,
                locationService: locationService,
                calendarService: calendarService,
                notificationService: notificationService
            )
            try? await Task.sleep(nanoseconds: 700_000_000)
            onComplete(alarm)
        }
    }
}
