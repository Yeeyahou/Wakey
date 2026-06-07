import SwiftUI

enum WakeyTab: String, CaseIterable, Identifiable {
    case home = "홈"
    case alarm = "알람"
    case library = "라이브러리"
    case settings = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .alarm: "alarm.fill"
        case .library: "music.note.list"
        case .settings: "gearshape.fill"
        }
    }
}

enum AppRoute: Equatable {
    case tabs
    case create
    case generating(AlarmDraft)
    case detail(AlarmSong)
}

struct RootView: View {
    @EnvironmentObject private var alarmManager: AlarmManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var selectedTab: WakeyTab = .home
    @State private var route: AppRoute = .tabs

    var body: some View {
        Group {
            switch route {
            case .tabs:
                TabBarView(selectedTab: $selectedTab, onCreateAlarm: { route = .create }, onShowDetail: { route = .detail($0) })
            case .create:
                CreateAlarmView(onBack: { route = .tabs }, onGenerate: { route = .generating($0) })
            case .generating(let draft):
                GeneratingView(draft: draft) { alarm in
                    alarmManager.add(alarm)
                    route = .detail(alarm)
                }
            case .detail(let alarm):
                AlarmSongDetailView(alarm: alarm, onBack: { route = .tabs }, onComplete: {
                    selectedTab = .home
                    route = .tabs
                }, onDelete: {
                    notificationManager.cancel(alarm)
                    alarmManager.delete(alarm)
                    route = .tabs
                }, onUpdate: { updated in
                    alarmManager.update(updated)
                    route = .detail(updated)
                }, onRegenerate: { draft in
                    notificationManager.cancel(alarm)
                    alarmManager.delete(alarm)
                    route = .generating(draft)
                })
            }
        }
        .tint(WakeyColors.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            notificationManager.refreshStatus()
        }
    }
}

struct TabBarView: View {
    @Binding var selectedTab: WakeyTab
    let onCreateAlarm: () -> Void
    let onShowDetail: (AlarmSong) -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onCreateAlarm: onCreateAlarm, onShowDetail: onShowDetail)
                .tabItem { Label(WakeyTab.home.rawValue, systemImage: WakeyTab.home.icon) }
                .tag(WakeyTab.home)
            AlarmListView(onCreateAlarm: onCreateAlarm, onShowDetail: onShowDetail)
                .tabItem { Label(WakeyTab.alarm.rawValue, systemImage: WakeyTab.alarm.icon) }
                .tag(WakeyTab.alarm)
            LibraryView(onShowDetail: onShowDetail)
                .tabItem { Label(WakeyTab.library.rawValue, systemImage: WakeyTab.library.icon) }
                .tag(WakeyTab.library)
            SettingsView()
                .tabItem { Label(WakeyTab.settings.rawValue, systemImage: WakeyTab.settings.icon) }
                .tag(WakeyTab.settings)
        }
        .tint(WakeyColors.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
