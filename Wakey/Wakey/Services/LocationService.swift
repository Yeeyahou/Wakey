import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastMessage: String?

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func refreshStatus() {
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func currentLocationSummary() async -> String? {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            await MainActor.run { manager.requestWhenInUseAuthorization() }
            try? await Task.sleep(nanoseconds: 800_000_000)
        }

        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            await MainActor.run { lastMessage = "위치 권한이 없어 위치 정보는 제외했어요." }
            return nil
        }

        let location = await requestSingleLocation()
        guard let location else {
            await MainActor.run { lastMessage = "현재 위치를 가져오지 못해 위치 정보는 제외했어요." }
            return nil
        }

        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
            let parts = [placemark.locality, placemark.subLocality, placemark.name]
                .compactMap { $0 }
                .removingDuplicates()
            if !parts.isEmpty {
                return parts.joined(separator: " ")
            }
        }

        return String(format: "위도 %.4f, 경도 %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }

    func currentLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return nil }
        return await requestSingleLocation()
    }

    private func requestSingleLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.last)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
