import Foundation

struct AlarmSong: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var date: Date
    var isEnabled: Bool
    var alarmName: String?
    var purpose: AlarmPurpose
    var mood: AlarmMood
    var nickname: String
    var memo: String
    var repeatDays: Set<Weekday>
    var snoozeEnabled: Bool?
    var snoozeIntervalMinutes: Int?
    var snoozeRepeatCount: Int?
    var lyrics: String?
    var originalAudioFilePath: String?
    var notificationAudioFilePath: String?
    var alarmVolume: Float?
    var usesAIAlarmSong: Bool?
    var generatedAt: Date?
    var weatherSummary: String?
    var locationSummary: String?
    var calendarSummary: String?
    var isAlarmDeleted: Bool?
    var isLibraryDeleted: Bool?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        time: Date,
        date: Date = Date(),
        isEnabled: Bool = true,
        alarmName: String? = nil,
        purpose: AlarmPurpose,
        mood: AlarmMood,
        nickname: String,
        memo: String,
        repeatDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday],
        snoozeEnabled: Bool? = nil,
        snoozeIntervalMinutes: Int? = nil,
        snoozeRepeatCount: Int? = nil,
        lyrics: String? = nil,
        originalAudioFilePath: String? = nil,
        notificationAudioFilePath: String? = nil,
        alarmVolume: Float? = nil,
        usesAIAlarmSong: Bool? = nil,
        generatedAt: Date? = nil,
        weatherSummary: String? = nil,
        locationSummary: String? = nil,
        calendarSummary: String? = nil,
        isAlarmDeleted: Bool? = nil,
        isLibraryDeleted: Bool? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.date = date
        self.isEnabled = isEnabled
        self.alarmName = alarmName
        self.purpose = purpose
        self.mood = mood
        self.nickname = nickname
        self.memo = memo
        self.repeatDays = repeatDays
        self.snoozeEnabled = snoozeEnabled
        self.snoozeIntervalMinutes = snoozeIntervalMinutes
        self.snoozeRepeatCount = snoozeRepeatCount
        self.lyrics = lyrics
        self.originalAudioFilePath = originalAudioFilePath
        self.notificationAudioFilePath = notificationAudioFilePath
        self.alarmVolume = alarmVolume
        self.usesAIAlarmSong = usesAIAlarmSong
        self.generatedAt = generatedAt
        self.weatherSummary = weatherSummary
        self.locationSummary = locationSummary
        self.calendarSummary = calendarSummary
        self.isAlarmDeleted = isAlarmDeleted
        self.isLibraryDeleted = isLibraryDeleted
        self.createdAt = createdAt
    }
}

extension AlarmSong {
    var originalAudioURL: URL? {
        Self.resolveStoredAudioPath(originalAudioFilePath, directory: .documentDirectory)
    }

    var notificationAudioURL: URL? {
        Self.resolveStoredAudioPath(notificationAudioFilePath, directory: .librarySounds)
    }

    var notificationSoundFileName: String? {
        notificationAudioURL?.lastPathComponent
    }

    var audioURL: URL? {
        get { originalAudioURL }
        set { originalAudioFilePath = newValue?.lastPathComponent }
    }

    var weather: String? {
        get { weatherSummary }
        set { weatherSummary = newValue }
    }

    var location: String? {
        get { locationSummary }
        set { locationSummary = newValue }
    }

    var calendarEvent: String? {
        get { calendarSummary }
        set { calendarSummary = newValue }
    }

    var isAIAlarmSong: Bool {
        usesAIAlarmSong == true || lyrics != nil || originalAudioFilePath != nil
    }

    var isVisibleAlarm: Bool {
        isAlarmDeleted != true
    }

    var isVisibleLibrarySong: Bool {
        isAIAlarmSong && isLibraryDeleted != true
    }

    var resolvedAlarmVolume: Float {
        min(max(alarmVolume ?? 0.8, 0), 1)
    }

    private enum AudioStorageDirectory {
        case documentDirectory
        case librarySounds
    }

    private static func resolveStoredAudioPath(_ storedPath: String?, directory: AudioStorageDirectory) -> URL? {
        guard let storedPath, !storedPath.isEmpty else { return nil }

        let storedURL = URL(fileURLWithPath: storedPath)
        if storedURL.isFileURL, storedPath.hasPrefix("/"), FileManager.default.fileExists(atPath: storedURL.path) {
            return storedURL
        }

        let fileName = storedURL.lastPathComponent
        guard !fileName.isEmpty else { return nil }

        let baseURL: URL?
        switch directory {
        case .documentDirectory:
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        case .librarySounds:
            baseURL = try? AudioFileService.librarySoundsDirectory()
        }

        guard let resolvedURL = baseURL?.appendingPathComponent(fileName) else { return nil }
        return FileManager.default.fileExists(atPath: resolvedURL.path) ? resolvedURL : nil
    }
}

enum AlarmPurpose: String, Codable, CaseIterable, Identifiable {
    case wakeup = "기상"
    case work = "출근"
    case school = "등교"
    case exercise = "운동"
    case study = "공부"
    case other = "기타"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "기상":
            self = .wakeup
        case "출근":
            self = .work
        case "등교":
            self = .school
        case "운동":
            self = .exercise
        case "공부":
            self = .study
        case "기타", "시험":
            self = .other
        default:
            self = .other
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum AlarmMood: String, Codable, CaseIterable, Identifiable {
    case exciting = "신나는"
    case soft = "잔잔한"
    case emotional = "감성적인"
    case rock = "락"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "신나는", "활기찬", "귀여운", "응원하는":
            self = .exciting
        case "잔잔한", "차분한":
            self = .soft
        case "감성적인":
            self = .emotional
        case "락":
            self = .rock
        default:
            self = .exciting
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case monday = "월"
    case tuesday = "화"
    case wednesday = "수"
    case thursday = "목"
    case friday = "금"
    case saturday = "토"
    case sunday = "일"

    var id: String { rawValue }
}

struct AlarmDraft: Equatable {
    var time: Date = .alarmTime(hour: 7, minute: 0)
    var selectedDate: Date?
    var alarmName = ""
    var nickname = WakeyProfile.defaultNickname
    var includeNameInLyrics = true
    var useCustomSong = true
    var defaultAlarmSoundFileName: String?
    var defaultAlarmVolume: Float = 0.8
    var snoozeEnabled = true
    var snoozeIntervalMinutes = 5
    var snoozeRepeatCount: Int? = 3
    var purpose: AlarmPurpose = .wakeup
    var mood: AlarmMood = .exciting
    var memo = ""
    var repeatDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var useLocation = false
    var useWeather = false
    var useCalendar = false
}
