import Foundation
import EventKit
import Combine

final class CalendarService: ObservableObject {
    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var lastMessage: String?

    private let store = EKEventStore()

    func refreshStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestPermission() {
        Task {
            _ = await requestAccessIfNeeded()
            await MainActor.run { refreshStatus() }
        }
    }

    func todaySummary() async -> String? {
        guard await requestAccessIfNeeded() else {
            await MainActor.run { lastMessage = "캘린더 권한이 없어 일정 정보는 제외했어요." }
            return nil
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let titles = store.events(matching: predicate)
            .filter { !$0.isAllDay || $0.endDate > Date() }
            .sorted { $0.startDate < $1.startDate }
            .prefix(3)
            .map(\.title)
            .filter { !$0.isEmpty }

        guard !titles.isEmpty else { return nil }
        return "오늘 일정: \(titles.joined(separator: ", "))"
    }

    private func requestAccessIfNeeded() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        await MainActor.run { authorizationStatus = status }

        switch status {
        case .fullAccess, .authorized:
            return true
        case .notDetermined:
            do {
                let granted: Bool
                if #available(iOS 17.0, *) {
                    granted = try await store.requestFullAccessToEvents()
                } else {
                    granted = try await store.requestAccess(to: .event)
                }
                await MainActor.run { authorizationStatus = EKEventStore.authorizationStatus(for: .event) }
                return granted
            } catch {
                return false
            }
        case .denied, .restricted, .writeOnly:
            return false
        @unknown default:
            return false
        }
    }
}
