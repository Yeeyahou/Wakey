import Foundation
import Combine
import UserNotifications

final class NotificationService: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestPermission() {
        Task {
            _ = try? await requestPermissionIfNeeded()
        }
    }

    @discardableResult
    func requestPermissionIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        await MainActor.run { authorizationStatus = settings.authorizationStatus }

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            refreshStatus()
            return granted
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func schedule(_ alarm: AlarmSong) async throws {
        guard alarm.isEnabled else {
            cancel(alarm)
            return
        }

        guard try await requestPermissionIfNeeded() else {
            throw NotificationError.permissionDenied
        }

        cancel(alarm)

        let content = UNMutableNotificationContent()
        content.title = alarm.alarmName ?? "Wakey"
        content.body = "알람을 끄려면 열어주세요."
        content.userInfo = [
            "alarmId": alarm.id.uuidString
        ]
        if let fileName = alarm.notificationSoundFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(fileName))
        } else {
            content.sound = .default
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
        if alarm.repeatDays.isEmpty {
            var onceComponents = Calendar.current.dateComponents([.year, .month, .day], from: onceFireDate(for: alarm))
            onceComponents.hour = components.hour
            onceComponents.minute = components.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: onceComponents, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            try await UNUserNotificationCenter.current().add(request)
        } else {
            for day in alarm.repeatDays {
                var repeatedComponents = DateComponents()
                repeatedComponents.weekday = day.calendarWeekday
                repeatedComponents.hour = components.hour
                repeatedComponents.minute = components.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: repeatedComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(alarm.id.uuidString)-\(day.id)", content: content, trigger: trigger)
                try await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func cancel(_ alarm: AlarmSong) {
        let identifiers = [alarm.id.uuidString] + Weekday.allCases.map { "\(alarm.id.uuidString)-\($0.id)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func onceFireDate(for alarm: AlarmSong) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)
        let fireDate = calendar.date(
            bySettingHour: timeComponents.hour ?? 7,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: alarm.date
        ) ?? alarm.date

        if fireDate > Date() {
            return fireDate
        }
        return calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
    }

    enum NotificationError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            "알림 권한이 필요합니다."
        }
    }
}

typealias NotificationManager = NotificationService

private extension Weekday {
    var calendarWeekday: Int {
        switch self {
        case .sunday: 1
        case .monday: 2
        case .tuesday: 3
        case .wednesday: 4
        case .thursday: 5
        case .friday: 6
        case .saturday: 7
        }
    }
}
