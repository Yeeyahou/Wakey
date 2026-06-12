import SwiftUI

struct AlarmListView: View {
    @EnvironmentObject private var alarmManager: AlarmManager
    @EnvironmentObject private var notificationManager: NotificationManager
    let onCreateAlarm: () -> Void
    let onShowDetail: (AlarmSong) -> Void
    @State private var alarmToDelete: AlarmSong?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("알람")
                        .font(.system(size: 31, weight: .semibold))
                    Spacer()
                    IconCircleButton(systemName: "plus", action: onCreateAlarm)
                }

                if alarmManager.sortedAlarms.isEmpty {
                    EmptyStateView(icon: "plus", title: "알람이 없어요", message: "새 알람송을 만들어 알람을 추가하세요")
                } else {
                    VStack(spacing: 14) {
                        ForEach(alarmManager.sortedAlarms) { alarm in
                            AlarmCard(
                                alarm: alarm,
                                onOpen: { onShowDetail(alarm) },
                                onToggle: {
                                    Task { await toggle(alarm) }
                                },
                                onDelete: { alarmToDelete = alarm }
                            )
                                .swipeActions {
                                    Button(role: .destructive) { alarmToDelete = alarm } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    statsCard
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .wakeyScreenBackground()
        .alert("알람을 삭제할까요?", isPresented: Binding(get: { alarmToDelete != nil }, set: { if !$0 { alarmToDelete = nil } })) {
            Button("삭제", role: .destructive) {
                if let alarmToDelete {
                    notificationManager.cancel(alarmToDelete)
                    alarmManager.deleteAlarm(alarmToDelete)
                }
                alarmToDelete = nil
            }
            Button("취소", role: .cancel) { alarmToDelete = nil }
        }
    }

    private func toggle(_ alarm: AlarmSong) async {
        guard let updated = alarmManager.setEnabled(alarm, isEnabled: !alarm.isEnabled) else { return }
        if updated.isEnabled {
            try? await notificationManager.schedule(updated)
        } else {
            notificationManager.cancel(updated)
        }
    }

    private var statsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("활성 알람")
                    .font(.system(size: 14))
                    .foregroundStyle(WakeyColors.textSecondary)
                Text("\(alarmManager.enabledAlarms.count)개")
                    .font(.system(size: 28, weight: .semibold))
            }
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Text("전체 알람")
                    .font(.system(size: 14))
                    .foregroundStyle(WakeyColors.textSecondary)
                Text("\(alarmManager.sortedAlarms.count)개")
                    .font(.system(size: 28, weight: .semibold))
            }
        }
        .padding(24)
        .background(LinearGradient.wakeySoft)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct AlarmCard: View {
    let alarm: AlarmSong
    let onOpen: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Text(alarm.time.alarmTimeText)
                    .font(.system(size: 31, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        alarmChips
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        alarmChips
                    }
                }

                HStack(spacing: 6) {
                    ForEach(Weekday.allCases) { day in
                        Text(day.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(alarm.repeatDays.contains(day) ? WakeyColors.primary : WakeyColors.textSecondary.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(alarm.repeatDays.contains(day) ? WakeyColors.primary.opacity(0.16) : Color.clear)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: 260)

                if !alarm.memo.isEmpty {
                    Text(alarm.memo)
                        .font(.system(size: 14))
                        .foregroundStyle(WakeyColors.textSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: 10) {
                    Label("편집", systemImage: "slider.horizontal.3")
                    Text("·").foregroundStyle(WakeyColors.textSecondary.opacity(0.4))
                    Button(action: onDelete) {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .tint(WakeyColors.primary)
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    alarm.isAIAlarmSong
                        ? WakeyColors.primary.opacity(0.18)
                        : Color.black.opacity(0.05),
                    lineWidth: alarm.isAIAlarmSong ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .opacity(alarm.isEnabled ? 1 : 0.60)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(alarm.isEnabled ? WakeyColors.primary.opacity(0.30) : Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture(perform: onOpen)
    }

    private var alarmChips: some View {
        Group {
            WakeyChip(text: alarm.purpose.rawValue, color: WakeyColors.secondary)
            WakeyChip(text: alarm.mood.rawValue, color: WakeyColors.primary)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if alarm.isAIAlarmSong {
            LinearGradient(
                colors: [
                    Color(hex: "FFF8E8"),
                    Color(hex: "FFEAF2"),
                    Color(hex: "EEF7FF")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            WakeyColors.cardBackground
        }
    }
}
