import Foundation
import Combine

@MainActor
final class GeneratingViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case gatheringContext
        case generatingLyrics
        case requestingMusic
        case pollingMusic
        case downloadingAudio
        case creatingNotificationAudio
        case scheduling
        case completed
        case failed(String)

        var message: String {
            switch self {
            case .idle:
                "알람송 생성을 준비하고 있어요."
            case .gatheringContext:
                "알람 정보를 모으는 중입니다."
            case .generatingLyrics:
                "가사를 생성하는 중입니다."
            case .requestingMusic:
                "음악 생성을 요청하는 중입니다."
            case .pollingMusic:
                "알람송을 생성하는 중입니다."
            case .downloadingAudio:
                "음악 파일을 저장하는 중입니다."
            case .creatingNotificationAudio:
                "알림용 짧은 사운드를 만드는 중입니다."
            case .scheduling:
                "알람을 예약하는 중입니다."
            case .completed:
                "알람이 저장되었습니다."
            case .failed(let message):
                message
            }
        }
    }

    @Published var phase: Phase = .idle
    @Published var lyrics: String?
    @Published var statusDetail: String?
    @Published var canContinueAfterFailure = false

    private let lyricsGenerator = LyricsGenerator()
    private let sunoService = SunoService()
    private let audioFileService = AudioFileService()

    func generate(
        draft: AlarmDraft,
        weatherService: WeatherService,
        locationService: LocationService,
        calendarService: CalendarService,
        notificationService: NotificationManager
    ) async -> AlarmSong {
        let alarmId = UUID()

        phase = .gatheringContext
        async let locationSummary = draft.useLocation ? locationService.currentLocationSummary() : nil
        async let location = draft.useWeather ? locationService.currentLocation() : nil
        async let calendarSummary = draft.useCalendar ? calendarService.todaySummary() : nil

        let resolvedLocationSummary = await locationSummary
        let resolvedWeatherSummary = draft.useWeather ? await weatherService.currentWeatherSummary(for: await location) : nil
        let resolvedCalendarSummary = await calendarSummary

        phase = .generatingLyrics
        let context = LyricsContext(
            date: Date(),
            nickname: draft.nickname,
            purpose: draft.purpose,
            memo: draft.memo,
            mood: draft.mood,
            locationSummary: resolvedLocationSummary,
            weatherSummary: resolvedWeatherSummary,
            calendarSummary: resolvedCalendarSummary
        )
        let generatedLyrics = lyricsGenerator.generate(context: context)
        lyrics = generatedLyrics

        var originalAudioURL: URL?
        var notificationAudioURL: URL?

        do {
            phase = .requestingMusic
            let taskId = try await sunoService.generateSong(lyrics: generatedLyrics, mood: draft.mood.rawValue)
            statusDetail = "Suno 작업 ID: \(taskId)"

            phase = .pollingMusic
            let remoteAudioURL = try await sunoService.pollUntilComplete(taskId: taskId)

            phase = .downloadingAudio
            originalAudioURL = try await sunoService.downloadAudio(from: remoteAudioURL, alarmId: alarmId)

            if let originalAudioURL {
                phase = .creatingNotificationAudio
                notificationAudioURL = try? await audioFileService.createShortNotificationAudio(from: originalAudioURL, alarmId: alarmId)
            }
        } catch SunoService.SunoError.missingAPIKey {
            // The app can still create a useful local alarm without Suno credentials.
            // Configure SunoService.apiKey to enable real MP3 generation.
            statusDetail = "Suno API 키가 없어 가사와 기본 알림으로 저장합니다."
        } catch {
            statusDetail = "음악 생성에 실패해 가사와 기본 알림으로 저장합니다."
        }

        var alarm = AlarmSong(
            id: alarmId,
            time: draft.time,
            date: Date(),
            purpose: draft.purpose,
            mood: draft.mood,
            nickname: draft.nickname,
            memo: draft.memo,
            repeatDays: draft.repeatDays,
            lyrics: generatedLyrics,
            originalAudioFilePath: originalAudioURL?.path,
            notificationAudioFilePath: notificationAudioURL?.path,
            generatedAt: Date(),
            weatherSummary: resolvedWeatherSummary,
            locationSummary: resolvedLocationSummary,
            calendarSummary: resolvedCalendarSummary,
            createdAt: Date()
        )

        phase = .scheduling
        do {
            try await notificationService.schedule(alarm)
        } catch {
            alarm.isEnabled = false
            statusDetail = "알림 권한이 없어 알람은 저장했지만 예약하지 못했어요."
        }

        phase = .completed
        return alarm
    }
}
