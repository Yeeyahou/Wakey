import Foundation
import Combine

final class AlarmManager: ObservableObject {
    @Published private(set) var alarms: [AlarmSong] = [] {
        didSet { save() }
    }

    private let storageKey = "wakey.alarms.v1"

    init() {
        load()
    }

    var sortedAlarms: [AlarmSong] {
        alarms.sorted { $0.time.alarmTimeText < $1.time.alarmTimeText }
    }

    var enabledAlarms: [AlarmSong] {
        alarms.filter(\.isEnabled)
    }

    var nextAlarm: AlarmSong? {
        sortedAlarms.first(where: \.isEnabled)
    }

    var recentGenerated: AlarmSong? {
        alarms
            .filter { $0.lyrics != nil }
            .sorted { ($0.generatedAt ?? .distantPast) > ($1.generatedAt ?? .distantPast) }
            .first
    }

    func add(_ alarm: AlarmSong) {
        alarms.append(alarm)
    }

    func upsert(_ alarm: AlarmSong) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
    }

    func update(_ alarm: AlarmSong) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index] = alarm
    }

    func toggle(_ alarm: AlarmSong) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
    }

    func setEnabled(_ alarm: AlarmSong, isEnabled: Bool) -> AlarmSong? {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return nil }
        alarms[index].isEnabled = isEnabled
        return alarms[index]
    }

    func delete(_ alarm: AlarmSong) {
        alarms.removeAll { $0.id == alarm.id }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        alarms = (try? JSONDecoder().decode([AlarmSong].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(alarms) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static let sampleLyrics = """
    일어나요 지우야~
    오늘도 힘차게 시작해요
    맑은 하늘 아래
    새로운 하루가 기다려요

    따뜻한 아침 햇살이
    당신을 부르고 있어요
    활기차게 시작해봐요
    오늘도 멋진 하루 되세요!
    """

    var generatedSongs: [AlarmSong] {
        alarms
            .filter { $0.lyrics != nil || $0.originalAudioFilePath != nil }
            .sorted { ($0.generatedAt ?? $0.createdAt) > ($1.generatedAt ?? $1.createdAt) }
    }
}
