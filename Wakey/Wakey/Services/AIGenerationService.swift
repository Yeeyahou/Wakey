import Foundation

struct GeneratedAlarmSong {
    let lyrics: String
    let audioURL: URL?
}

struct AIGenerationService {
    func generateSong(from draft: AlarmDraft, weather: String?) async throws -> GeneratedAlarmSong {
        try await Task.sleep(nanoseconds: 3_000_000_000)
        let lyrics = """
        일어나요 \(draft.nickname)야~
        오늘도 힘차게 시작해요
        \(weather ?? "따뜻한 아침") 아래
        새로운 하루가 기다려요

        \(draft.mood.rawValue) 마음으로
        \(draft.purpose.rawValue) 준비를 해봐요
        \(draft.memo.isEmpty ? "오늘도 멋진 하루 되세요!" : draft.memo)
        Wakey가 함께할게요!
        """
        return GeneratedAlarmSong(lyrics: lyrics, audioURL: nil)
    }
}
