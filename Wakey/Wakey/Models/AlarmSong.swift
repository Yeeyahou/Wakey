import Foundation

struct AlarmSong: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var date: Date
    var isEnabled: Bool
    var purpose: AlarmPurpose
    var mood: AlarmMood
    var nickname: String
    var memo: String
    var repeatDays: Set<Weekday>
    var lyrics: String?
    var originalAudioFilePath: String?
    var notificationAudioFilePath: String?
    var generatedAt: Date?
    var weatherSummary: String?
    var locationSummary: String?
    var calendarSummary: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        time: Date,
        date: Date = Date(),
        isEnabled: Bool = true,
        purpose: AlarmPurpose,
        mood: AlarmMood,
        nickname: String,
        memo: String,
        repeatDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday],
        lyrics: String? = nil,
        originalAudioFilePath: String? = nil,
        notificationAudioFilePath: String? = nil,
        generatedAt: Date? = nil,
        weatherSummary: String? = nil,
        locationSummary: String? = nil,
        calendarSummary: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.date = date
        self.isEnabled = isEnabled
        self.purpose = purpose
        self.mood = mood
        self.nickname = nickname
        self.memo = memo
        self.repeatDays = repeatDays
        self.lyrics = lyrics
        self.originalAudioFilePath = originalAudioFilePath
        self.notificationAudioFilePath = notificationAudioFilePath
        self.generatedAt = generatedAt
        self.weatherSummary = weatherSummary
        self.locationSummary = locationSummary
        self.calendarSummary = calendarSummary
        self.createdAt = createdAt
    }
}

extension AlarmSong {
    var originalAudioURL: URL? {
        guard let originalAudioFilePath else { return nil }
        return URL(fileURLWithPath: originalAudioFilePath)
    }

    var notificationAudioURL: URL? {
        guard let notificationAudioFilePath else { return nil }
        return URL(fileURLWithPath: notificationAudioFilePath)
    }

    var notificationSoundFileName: String? {
        notificationAudioURL?.lastPathComponent
    }

    var audioURL: URL? {
        get { originalAudioURL }
        set { originalAudioFilePath = newValue?.path }
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
}

enum AlarmPurpose: String, Codable, CaseIterable, Identifiable {
    case wakeup = "기상"
    case school = "등교"
    case work = "출근"
    case exam = "시험"
    case exercise = "운동"
    case study = "공부"

    var id: String { rawValue }
}

enum AlarmMood: String, Codable, CaseIterable, Identifiable {
    case energetic = "활기찬"
    case calm = "차분한"
    case emotional = "감성적인"
    case cute = "귀여운"
    case encouraging = "응원하는"
    case exciting = "신나는"

    var id: String { rawValue }
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
    var nickname = "지우"
    var purpose: AlarmPurpose = .wakeup
    var mood: AlarmMood = .energetic
    var memo = "오늘도 힘차게 시작하는 하루!"
    var repeatDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    var useLocation = false
    var useWeather = true
    var useCalendar = false
}
