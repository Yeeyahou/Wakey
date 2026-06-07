import Foundation
import Combine
import CoreLocation
import WeatherKit

final class WeatherService: ObservableObject {
    @Published var summary = "맑음 23°C"
    @Published var iconName = "cloud.sun"

    func refreshMockWeather() async {
        summary = "맑음 23°C"
        iconName = "cloud.sun"
    }

    func currentWeatherSummary(for location: CLLocation?) async -> String? {
        guard let location else { return nil }

        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
            let temperature = Int(weather.currentWeather.temperature.converted(to: .celsius).value.rounded())
            let condition = weather.currentWeather.condition.koreanText
            let result = "\(condition), \(temperature)도"

            await MainActor.run {
                summary = result
                iconName = weather.currentWeather.symbolName
            }

            return result
        } catch {
            // WeatherKit requires proper Apple Developer configuration and entitlement.
            // If unavailable, the alarm still works without weather context.
            return nil
        }
    }
}

private extension WeatherCondition {
    var koreanText: String {
        switch self {
        case .clear: "맑음"
        case .cloudy: "흐림"
        case .mostlyClear: "대체로 맑음"
        case .mostlyCloudy: "대체로 흐림"
        case .partlyCloudy: "구름 조금"
        case .rain: "비"
        case .drizzle: "이슬비"
        case .snow: "눈"
        case .sleet: "진눈깨비"
        case .windy: "바람"
        case .thunderstorms: "천둥번개"
        case .foggy: "안개"
        default: "날씨 확인됨"
        }
    }
}
