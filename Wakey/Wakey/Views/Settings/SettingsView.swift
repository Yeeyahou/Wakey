import SwiftUI
import UserNotifications
import CoreLocation
import EventKit

struct SettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var calendarService: CalendarService
    @AppStorage("wakey.profile.nickname") private var nickname = "지우"
    @AppStorage("wakey.settings.useWeather") private var useWeather = true
    @AppStorage("wakey.settings.useCalendar") private var useCalendar = false
    @State private var isEditingNickname = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("설정")
                    .font(.system(size: 31, weight: .semibold))
                profileSection
                permissionSection
                dataSection
                appInfoSection
                Text("Wakey © 2026")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WakeyColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 96)
        }
        .wakeyScreenBackground()
        .onAppear {
            notificationManager.refreshStatus()
            locationService.refreshStatus()
            calendarService.refreshStatus()
        }
    }

    private var profileSection: some View {
        SettingsSection(title: "프로필") {
            HStack(spacing: 14) {
                SettingsIcon(systemName: "person.fill", color: WakeyColors.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("닉네임")
                        .font(.system(size: 16, weight: .semibold))
                    if isEditingNickname {
                        TextField("닉네임", text: $nickname)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(nickname)
                            .font(.system(size: 14))
                            .foregroundStyle(WakeyColors.textSecondary)
                    }
                }
                Spacer()
                Button {
                    isEditingNickname.toggle()
                } label: {
                    Image(systemName: isEditingNickname ? "checkmark" : "chevron.right")
                        .foregroundStyle(WakeyColors.textSecondary)
                }
            }
        }
    }

    private var permissionSection: some View {
        SettingsSection(title: "권한 설정") {
            SettingsNavigationRow(
                icon: "bell.fill",
                color: WakeyColors.destructive,
                title: "알림",
                subtitle: notificationSubtitle
            ) {
                if notificationManager.authorizationStatus == .notDetermined {
                    notificationManager.requestPermission()
                } else {
                    openSettings()
                }
            }
            Divider()
            SettingsNavigationRow(
                icon: "mappin.and.ellipse",
                color: WakeyColors.accent,
                title: "위치",
                subtitle: locationSubtitle
            ) {
                if locationService.authorizationStatus == .notDetermined {
                    locationService.requestPermission()
                } else {
                    openSettings()
                }
            }
            Divider()
            SettingsNavigationRow(
                icon: "calendar",
                color: WakeyColors.primary,
                title: "캘린더",
                subtitle: calendarSubtitle
            ) {
                if calendarService.authorizationStatus == .notDetermined {
                    calendarService.requestPermission()
                } else {
                    openSettings()
                }
            }
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "데이터 사용") {
            ToggleRow(icon: "cloud.fill", title: "날씨 정보 사용", isOn: $useWeather)
            Divider()
            ToggleRow(icon: "calendar", title: "캘린더 연동", iconColor: WakeyColors.primary, isOn: $useCalendar)
        }
    }

    private var appInfoSection: some View {
        SettingsSection(title: "앱 정보") {
            HStack {
                SettingsIcon(systemName: "info.circle.fill", color: WakeyColors.textPrimary)
                Text("버전")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(WakeyColors.textSecondary)
            }
            Divider()
            SettingsNavigationRow(title: "이용 약관")
            Divider()
            SettingsNavigationRow(title: "개인정보 처리방침")
            Divider()
            SettingsNavigationRow(title: "오픈소스 라이선스")
        }
    }

    private var notificationSubtitle: String {
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral: "허용됨"
        case .denied: "허용 안 함"
        case .notDetermined: "권한 요청 필요"
        @unknown default: "확인 필요"
        }
    }

    private var locationSubtitle: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .authorized: "허용됨"
        case .denied, .restricted: "허용 안 함"
        case .notDetermined: "권한 요청 필요"
        @unknown default: "확인 필요"
        }
    }

    private var calendarSubtitle: String {
        let status = calendarService.authorizationStatus
        if #available(iOS 17.0, *) {
            switch status {
            case .fullAccess, .authorized: return "허용됨"
            case .writeOnly: return "읽기 권한 필요"
            case .denied, .restricted: return "허용 안 함"
            case .notDetermined: return "권한 요청 필요"
            @unknown default: return "확인 필요"
            }
        } else {
            switch status {
            case .authorized: return "허용됨"
            case .denied, .restricted: return "허용 안 함"
            case .notDetermined: return "권한 요청 필요"
            default: return "확인 필요"
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            content
        }
        .padding(22)
        .wakeyCard(cornerRadius: 24)
    }
}

private struct SettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 38, height: 38)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct SettingsNavigationRow: View {
    var icon: String?
    var color: Color = WakeyColors.textPrimary
    let title: String
    var subtitle: String?
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    SettingsIcon(systemName: icon, color: color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(WakeyColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(WakeyColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
