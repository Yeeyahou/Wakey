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
        VStack(spacing: 28) {
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

            ProgressView()
                .tint(WakeyColors.primary)
                .padding(.horizontal, 42)

            debugPanel
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

    private var debugPanel: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let elapsed = elapsedText(since: viewModel.startedAt, now: timeline.date)
            VStack(alignment: .leading, spacing: 8) {
                Text("DEBUG")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(WakeyColors.textSecondary)
                Text("phase: \(phaseLabel(viewModel.phase))")
                Text("step: \(viewModel.debugStep)")
                Text("elapsed: \(elapsed)")
                Text("lyrics: \(viewModel.lyrics?.count ?? 0) chars")
                Text("status: \(viewModel.statusDetail ?? "-")")
                Text("suno:\n\(viewModel.sunoDebugInfo)")
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(WakeyColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(WakeyColors.cardBackground.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 28)
        }
    }

    private func phaseLabel(_ phase: GeneratingViewModel.Phase) -> String {
        switch phase {
        case .idle: return "idle"
        case .gatheringContext: return "gatheringContext"
        case .generatingLyrics: return "generatingLyrics"
        case .requestingMusic: return "requestingMusic"
        case .pollingMusic: return "pollingMusic"
        case .downloadingAudio: return "downloadingAudio"
        case .creatingNotificationAudio: return "creatingNotificationAudio"
        case .scheduling: return "scheduling"
        case .completed: return "completed"
        case .failed(let message): return "failed(\(message))"
        }
    }

    private func elapsedText(since startedAt: Date?, now: Date) -> String {
        guard let startedAt else { return "-" }
        let seconds = max(0, Int(now.timeIntervalSince(startedAt)))
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
}
