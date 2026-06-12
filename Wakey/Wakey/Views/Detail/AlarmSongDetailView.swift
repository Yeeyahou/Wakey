import SwiftUI
import AVFoundation

struct AlarmSongDetailView: View {
    let alarm: AlarmSong
    let onBack: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onUpdate: (AlarmSong) -> Void
    let onRegenerate: (AlarmDraft) -> Void

    @EnvironmentObject private var notificationManager: NotificationManager

    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var progress = 0.30
    @State private var message: String?

    var body: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(spacing: 24) {
                    timeHeader
                    infoCard(title: "메모", value: alarm.memo.isEmpty ? "메모가 없어요" : "\"\(alarm.memo)\"")
                    lyricsCard
                    audioCard
                    detailCard
                    limitationCard
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 150)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .wakeyScreenBackground()
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Text(alarmTitle)
                .font(.system(size: 22, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(WakeyColors.background.opacity(0.96))
        .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.05)).frame(height: 1) }
    }

    private var timeHeader: some View {
        VStack(spacing: 12) {
            Text(alarmTitle)
                .font(.system(size: 25, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(alarm.time.alarmTimeText)
                .font(.system(size: 54, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack {
                WakeyChip(text: alarm.purpose.rawValue, color: WakeyColors.secondary)
                WakeyChip(text: alarm.mood.rawValue, color: WakeyColors.accent)
            }
        }
    }

    private var alarmTitle: String {
        let title = alarm.alarmName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "Wakey Alarm Song" : title
    }

    private func infoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            Text(value)
                .font(.system(size: 17))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .wakeyCard(cornerRadius: 24)
    }

    private var lyricsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("가사 미리보기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WakeyColors.textSecondary)
                Spacer()
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(WakeyColors.primary)
            }
            ScrollView {
                Text(alarm.lyrics ?? AlarmManager.sampleLyrics)
                    .font(.system(size: 18))
                    .lineSpacing(7)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 270)
        }
        .padding(24)
        .background(LinearGradient.wakeySoft)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var audioCard: some View {
        HStack(spacing: 18) {
            Button {
                audioPlayer.toggle(url: alarm.originalAudioURL)
                message = audioPlayer.message
                withAnimation(.linear(duration: 0.35)) {
                    progress = audioPlayer.isPlaying ? min(progress + 0.10, 0.95) : progress
                }
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 66, height: 66)
                    .background(LinearGradient.wakeyButton)
                    .clipShape(Circle())
                    .shadow(color: WakeyColors.primary.opacity(0.25), radius: 10, y: 6)
            }
            .buttonStyle(.plain)

            VStack(spacing: 10) {
                Slider(value: $progress, in: 0...1)
                    .tint(WakeyColors.primary)
                HStack {
                    Text(alarm.originalAudioURL == nil ? "오디오 없음" : "전체 노래")
                    Spacer()
                    Text(alarm.notificationAudioURL == nil ? "기본 알림음" : "알림음 준비됨")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
                if let message {
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WakeyColors.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(24)
        .wakeyCard(cornerRadius: 24)
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("알람 정보")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            DetailRow(title: "생성 일시", value: (alarm.generatedAt ?? Date()).koreanGeneratedText)
            DetailRow(title: "날씨", value: alarm.weatherSummary ?? "반영 안 함")
            DetailRow(title: "위치", value: alarm.locationSummary ?? "반영 안 함")
            if let calendarEvent = alarm.calendarSummary {
                DetailRow(title: "일정", value: calendarEvent)
            }
        }
        .padding(24)
        .wakeyCard(cornerRadius: 24)
    }

    private var limitationCard: some View {
        Text("iOS 알림음은 30초 미만의 짧은 파일만 백그라운드에서 재생할 수 있어요. 전체 MP3는 앱 안에서 재생됩니다.")
            .font(.system(size: 13))
            .foregroundStyle(WakeyColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .wakeyCard(cornerRadius: 18)
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    onRegenerate(AlarmDraft(
                        time: alarm.time,
                        selectedDate: alarm.repeatDays.isEmpty ? alarm.date : nil,
                        alarmName: alarm.alarmName ?? "",
                        nickname: alarm.nickname,
                        snoozeEnabled: alarm.snoozeEnabled ?? true,
                        snoozeIntervalMinutes: alarm.snoozeIntervalMinutes ?? 5,
                        snoozeRepeatCount: alarm.snoozeRepeatCount ?? 3,
                        purpose: alarm.purpose,
                        mood: alarm.mood,
                        memo: alarm.memo,
                        repeatDays: alarm.repeatDays,
                        useLocation: alarm.locationSummary != nil,
                        useWeather: alarm.weatherSummary != nil,
                        useCalendar: alarm.calendarSummary != nil
                    ))
                } label: {
                    Text("다시 생성")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(WakeyColors.cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text("삭제")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WakeyColors.destructive)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(WakeyColors.cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Button {
                onComplete()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                    Text("완료")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(LinearGradient.wakeyButton)
                .clipShape(Capsule())
                .shadow(color: WakeyColors.primary.opacity(0.25), radius: 12, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(.ultraThinMaterial)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(WakeyColors.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 14))
    }
}
