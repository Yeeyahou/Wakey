import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var alarmManager: AlarmManager
    @EnvironmentObject private var weatherService: WeatherService
    let onCreateAlarm: () -> Void
    let onShowDetail: (AlarmSong) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                nextAlarmCard
                recentSongSection
                GradientButton(title: "나만의 알람송 만들기", systemImage: "plus", action: onCreateAlarm)
                statsGrid
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .wakeyScreenBackground()
        .task {
            await weatherService.refreshMockWeather()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("좋은 아침이에요!")
                .font(.system(size: 31, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            HStack(spacing: 8) {
                Image(systemName: weatherService.iconName)
                    .foregroundStyle(WakeyColors.accent)
                Text("\(Date().koreanFullDateText) · \(weatherService.summary)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(WakeyColors.textSecondary)
                    .lineLimit(2)
            }
        }
    }

    private var nextAlarmCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("다음 알람")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            if let alarm = alarmManager.nextAlarm {
                VStack(alignment: .leading, spacing: 10) {
                    Text(alarm.time.alarmTimeText)
                        .font(.system(size: 44, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    HStack(spacing: 10) {
                        WakeyChip(text: alarm.purpose.rawValue)
                        Text("\(alarm.mood.rawValue) 분위기")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(WakeyColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            } else {
                Text("예정된 알람이 없어요")
                    .font(.system(size: 24, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(LinearGradient.wakeySoft)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var recentSongSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 생성된 알람송")
                .font(.system(size: 23, weight: .semibold))
            if let alarm = alarmManager.recentGenerated {
                Button {
                    onShowDetail(alarm)
                } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Text(alarm.time.alarmTimeText)
                                    .font(.system(size: 23, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                WakeyChip(text: alarm.purpose.rawValue, color: WakeyColors.secondary)
                            }
                            Text("\"\((alarm.lyrics ?? "").split(separator: "\n").first ?? "알람송이 준비됐어요")\"")
                                .font(.system(size: 15))
                                .foregroundStyle(WakeyColors.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        IconCircleButton(systemName: "play.fill")
                    }
                    .padding(24)
                    .wakeyCard(cornerRadius: 26)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(value: "\(alarmManager.alarms.filter { $0.lyrics != nil }.count)", label: "생성된 알람송")
            StatCard(value: "\(alarmManager.enabledAlarms.count)", label: "활성 알람")
            StatCard(value: "85%", label: "정시 기상률")
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 31, weight: .medium))
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 108)
        .wakeyCard(cornerRadius: 18)
    }
}
