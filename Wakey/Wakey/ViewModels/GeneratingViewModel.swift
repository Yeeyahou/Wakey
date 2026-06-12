import Foundation
import Combine
import CoreLocation

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
    @Published var startedAt: Date?
    @Published var debugStep: String = "idle"
    @Published var sunoDebugInfo: String = "-"

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
        startedAt = Date()

        guard draft.useCustomSong else {
            phase = .scheduling
            debugStep = "default-alarm.schedule"
            var notificationAudioURL: URL?
            if let fileName = draft.defaultAlarmSoundFileName {
                debugStep = "default-alarm.copy-sound"
                if let bundledURL = AudioFileService.bundledAlarmSoundURLs().first(where: { $0.lastPathComponent == fileName }) {
                    notificationAudioURL = try? await audioFileService.createShortNotificationAudio(
                        from: bundledURL,
                        alarmId: alarmId,
                        volume: draft.defaultAlarmVolume
                    )
                }
            }
            var alarm = AlarmSong(
                id: alarmId,
                time: draft.time,
                date: draft.selectedDate ?? Date(),
                alarmName: draft.alarmName.isEmpty ? nil : draft.alarmName,
                purpose: draft.purpose,
                mood: draft.mood,
                nickname: draft.nickname,
                memo: draft.memo,
                repeatDays: draft.repeatDays,
                snoozeEnabled: draft.snoozeEnabled,
                snoozeIntervalMinutes: draft.snoozeIntervalMinutes,
                snoozeRepeatCount: draft.snoozeRepeatCount,
                notificationAudioFilePath: notificationAudioURL?.lastPathComponent,
                alarmVolume: draft.defaultAlarmVolume,
                usesAIAlarmSong: false,
                createdAt: Date()
            )

            do {
                try await notificationService.schedule(alarm)
            } catch {
                alarm.isEnabled = false
                statusDetail = "알림 권한이 없어 알람은 저장했지만 예약하지 못했어요."
            }

            phase = .completed
            return alarm
        }
        
        phase = .gatheringContext
        
        let alarmDate = nextFireDate(for: draft)
        let resolvedLocationSummary: String?
        if draft.useLocation {
            debugStep = "context.location-summary.start"
            resolvedLocationSummary = await locationService.currentLocationSummary()
            debugStep = resolvedLocationSummary == nil
                ? "context.location-summary.nil"
                : "context.location-summary.done"
        } else {
            debugStep = "context.location-summary.skipped"
            resolvedLocationSummary = nil
        }

        let resolvedWeatherLocation: CLLocation?
        if draft.useWeather {
            debugStep = "context.location.start"
            resolvedWeatherLocation = await locationService.currentLocation()
            debugStep = resolvedWeatherLocation == nil
                ? "context.location.nil"
                : "context.location.done"
        } else {
            debugStep = "context.location.skipped"
            resolvedWeatherLocation = nil
        }

        let resolvedCalendarSummary: String?
        if draft.useCalendar {
            debugStep = "context.calendar-summary.start"
            resolvedCalendarSummary = await calendarService.summary(for: draft.selectedDate ?? alarmDate)
            debugStep = resolvedCalendarSummary == nil
                ? "context.calendar-summary.nil"
                : "context.calendar-summary.done"
        } else {
            debugStep = "context.calendar-summary.skipped"
            resolvedCalendarSummary = nil
        }

        let resolvedWeatherSummary: String?
        if draft.useWeather {
            debugStep = "context.weather-summary.start"
            resolvedWeatherSummary = await weatherService.currentWeatherSummary(for: resolvedWeatherLocation)
            debugStep = resolvedWeatherSummary == nil
                ? "context.weather-summary.nil"
                : "context.weather-summary.done"
        } else {
            debugStep = "context.weather-summary.skipped"
            resolvedWeatherSummary = nil
        }

        

        phase = .generatingLyrics
        debugStep = "lyrics.generate"
        let generatedLyrics: String
        let aiSongTitle: String
        do {
            let generatedSong = try await lyricsGenerator.generate(
                draft: draft,
                alarmDate: alarmDate,
                locationSummary: resolvedLocationSummary,
                weatherSummary: resolvedWeatherSummary,
                calendarSummary: resolvedCalendarSummary
            )
            generatedLyrics = generatedSong.lyrics
            aiSongTitle = generatedSong.title
            lyrics = generatedLyrics
            if generatedLyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                statusDetail = "OpenAI 가사 생성 결과가 비어 있습니다."
                debugStep = "lyrics.empty"
            } else {
                debugStep = "lyrics.done"
            }
        } catch {
            lyrics = nil
            statusDetail = error.localizedDescription
            debugStep = "lyrics.error"
            print("Lyrics generation failed: \(error.localizedDescription)")
            phase = .failed(error.localizedDescription)
            return AlarmSong(
                id: alarmId,
                time: draft.time,
                date: draft.selectedDate ?? Date(),
                alarmName: draft.alarmName.isEmpty ? nil : draft.alarmName,
                purpose: draft.purpose,
                mood: draft.mood,
                nickname: draft.nickname,
                memo: draft.memo,
                repeatDays: draft.repeatDays,
                snoozeEnabled: draft.snoozeEnabled,
                snoozeIntervalMinutes: draft.snoozeIntervalMinutes,
                snoozeRepeatCount: draft.snoozeRepeatCount,
                lyrics: nil,
                usesAIAlarmSong: true,
                createdAt: Date()
            )
        }

        var originalAudioURL: URL?
        var notificationAudioURL: URL?
        var generatedSongTitle = aiSongTitle

        do {
            phase = .requestingMusic
            debugStep = "suno.generate"
            let requestTitle = aiSongTitle
            sunoDebugInfo = """
            request: preparing
            title: \(requestTitle)
            mood: \(draft.mood.rawValue)
            style: \(draft.mood.sunoStylePrompt)
            """
            let taskId = try await sunoService.generateSong(
                lyrics: generatedLyrics,
                mood: draft.mood,
                title: requestTitle
            )
            sunoDebugInfo = """
            request: submitted
            taskId: \(taskId)
            title: \(requestTitle)
            mood: \(draft.mood.rawValue)
            lyrics: \(generatedLyrics.count) chars
            """

            phase = .pollingMusic
            debugStep = "suno.poll"
            let generatedTrack = try await sunoService.pollUntilComplete(taskId: taskId) { [weak self] update in
                self?.debugStep = "suno.poll.\(update.status)"
                self?.sunoDebugInfo = """
                request: polling
                taskId: \(update.taskId)
                attempt: \(update.attempt)/\(update.maxAttempts)
                sunoStatus: \(update.status)
                hasTrack: \(update.hasTrack ? "yes" : "no")
                title: \(update.title ?? "-")
                audioURL: \(update.audioURL == nil ? "pending" : "received")
                """
            }
            sunoDebugInfo = """
            request: track-ready
            taskId: \(taskId)
            title: \(generatedSongTitle)
            audioURL: received
            """

            phase = .downloadingAudio
            debugStep = "suno.download"
            originalAudioURL = try await sunoService.downloadAudio(from: generatedTrack.audioURL, alarmId: alarmId)
            sunoDebugInfo = """
            request: downloaded
            taskId: \(taskId)
            title: \(generatedSongTitle)
            originalAudio: \(originalAudioURL?.lastPathComponent ?? "-")
            """

            phase = .creatingNotificationAudio
            debugStep = "audio.create-notification"
            if let originalAudioURL {
                notificationAudioURL = try? await audioFileService.createShortNotificationAudio(
                    from: originalAudioURL,
                    alarmId: alarmId,
                    volume: draft.defaultAlarmVolume
                )
            }
            sunoDebugInfo = """
            request: notification-audio
            taskId: \(taskId)
            title: \(generatedSongTitle)
            originalAudio: \(originalAudioURL?.lastPathComponent ?? "-")
            notificationAudio: \(notificationAudioURL?.lastPathComponent ?? "-")
            """
        } catch {
            statusDetail = error.localizedDescription
            debugStep = "suno.failed"
            sunoDebugInfo = """
            request: failed
            error: \(error.localizedDescription)
            """
        }

        let alarm = AlarmSong(
            id: alarmId,
            time: draft.time,
            date: draft.selectedDate ?? Date(),
            alarmName: generatedSongTitle.isEmpty ? nil : generatedSongTitle,
            purpose: draft.purpose,
            mood: draft.mood,
            nickname: draft.nickname,
            memo: draft.memo,
            repeatDays: draft.repeatDays,
            snoozeEnabled: draft.snoozeEnabled,
            snoozeIntervalMinutes: draft.snoozeIntervalMinutes,
            snoozeRepeatCount: draft.snoozeRepeatCount,
            lyrics: generatedLyrics,
            originalAudioFilePath: originalAudioURL?.lastPathComponent,
            notificationAudioFilePath: notificationAudioURL?.lastPathComponent,
            alarmVolume: draft.defaultAlarmVolume,
            usesAIAlarmSong: true,
            generatedAt: Date(),
            weatherSummary: resolvedWeatherSummary,
            locationSummary: resolvedLocationSummary,
            calendarSummary: resolvedCalendarSummary,
            createdAt: Date()
        )

        phase = .completed
        debugStep = "completed"
        return alarm
    }

    private func nextFireDate(for draft: AlarmDraft) -> Date {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: draft.time)
        let now = Date()

        if draft.repeatDays.isEmpty {
            let base = calendar.startOfDay(for: draft.selectedDate ?? Date())
            let date = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: base) ?? draft.time
            return date > now ? date : (calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        }

        return (0..<14).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            guard draft.repeatDays.contains(weekday(for: day)) else { return nil }
            let candidate = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: day)
            guard let candidate, candidate > now else { return nil }
            return candidate
        }.min() ?? now
    }

    private func weekday(for date: Date) -> Weekday {
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
}
