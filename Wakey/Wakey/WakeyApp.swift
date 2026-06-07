import SwiftUI

@main
struct WakeyApp: App {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var calendarService = CalendarService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(alarmManager)
                .environmentObject(weatherService)
                .environmentObject(notificationManager)
                .environmentObject(locationService)
                .environmentObject(calendarService)
        }
    }
}
