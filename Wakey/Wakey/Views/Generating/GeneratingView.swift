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

            Spacer()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(WakeyColors.primary)
                    .padding(.horizontal, 42)

                progressText
            }
            .padding(.bottom, 52)
            Spacer()
                .frame(height: 0)
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

    private var progressText: some View {
        Text(friendlyProgressText())
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(WakeyColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
    }

    private func friendlyProgressText() -> String {
        let step = viewModel.debugStep
        if step.contains("calendar") {
            return "캘린더 정보 읽는 중"
        }
        if step.contains("location") {
            return "위치 정보 불러오는 중"
        }
        if step.contains("weather") {
            return "날씨 정보 확인 중"
        }
        if step.contains("lyrics") {
            return "AI가 가사 생성 중"
        }
        if step.contains("suno.generate") {
            return "Suno에 알람송 요청 중"
        }
        if step.contains("suno.poll") {
            return "노래가 완성되기를 기다리는 중"
        }
        if step.contains("suno.download") {
            return "완성된 노래 저장 중"
        }
        if step.contains("audio.create-notification") {
            return "알림용 오디오 준비 중"
        }
        if step.contains("schedule") {
            return "알람 예약 중"
        }
        switch viewModel.phase {
        case .idle, .gatheringContext:
            return "알람 정보를 모으는 중"
        case .generatingLyrics:
            return "AI가 가사 생성 중"
        case .requestingMusic:
            return "Suno에 알람송 요청 중"
        case .pollingMusic:
            return "노래가 완성되기를 기다리는 중"
        case .downloadingAudio:
            return "완성된 노래 저장 중"
        case .creatingNotificationAudio:
            return "알림용 오디오 준비 중"
        case .scheduling:
            return "알람 예약 중"
        case .completed:
            return "알람송 준비 완료"
        case .failed:
            return viewModel.statusDetail ?? "생성 중 문제가 발생했어요"
        }
    }

}
