import Foundation

struct LyricsContext {
    let date: Date
    let nickname: String?
    let purpose: AlarmPurpose
    let memo: String
    let mood: AlarmMood
    let locationSummary: String?
    let weatherSummary: String?
    let calendarSummary: String?
}

struct LyricsGenerator {
    func generate(context: LyricsContext) -> String {
        let dateLine = "\(context.date.koreanFullDateText)"
        let weatherLine = context.weatherSummary.map { "오늘 날씨는 \($0), 기분 좋게 시작해요" }
        let locationLine = context.locationSummary.map { "\($0)에서 맞이하는 새로운 아침" }
        let calendarLine = context.calendarSummary.map { "\($0), 차근차근 해낼 수 있어요" }
        let memoLine = context.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(context.purpose.rawValue) 준비를 시작해요"
            : context.memo.trimmingCharacters(in: .whitespacesAndNewlines)

        let moodLine: String
        switch context.mood {
        case .exciting:
            moodLine = "신나는 리듬에 맞춰 일어나요"
        case .soft:
            moodLine = "잔잔하게 눈을 떠봐요"
        case .emotional:
            moodLine = "따뜻한 마음으로 하루를 열어요"
        case .rock:
            moodLine = "강한 비트로 몸을 깨워요"
        }

        var lines = [
            context.nickname.map { "좋은 아침 \($0)아" } ?? "좋은 아침이에요",
            "\(dateLine), 햇살이 널 불러",
            weatherLine,
            locationLine,
            "\(memoLine)",
            calendarLine,
            moodLine,
            "일어나요, 일어나요, \(context.purpose.rawValue) 시간이에요",
            "Wakey와 함께 오늘을 시작해요",
            "일어나요, 일어나요, 반짝이는 하루예요"
        ].compactMap { $0 }

        if lines.count > 10 {
            lines = Array(lines.prefix(10))
        }

        return lines.joined(separator: "\n")
    }
}
