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

struct GeneratedLyrics {
    let title: String
    let lyrics: String
}

struct GeminiService {
    // Add your Gemini API key here when you are ready to use live lyric generation.
    // Example: var apiKey = "YOUR_GEMINI_API_KEY"
    // Previous Gemini key placeholder:
    // var apiKey = "YOUR_GEMINI_API_KEY"
    var apiKey = ""
    var modelName = "gemini-3.5-flash"

    func generateLyrics(prompt: String) async throws -> GeneratedLyrics {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent")
        guard let url = components?.url else { throw GeminiError.badResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(trimmedKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [
            GeminiContent(parts: [GeminiPart(text: prompt)])
        ]))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await performRequestWithRetry(request)
        } catch {
            print("Gemini request failed: \(error.localizedDescription)")
            throw error
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("""
            Gemini HTTP error:
            statusCode=\(statusCode)
            body=\(responseBody)
            """)
            if statusCode == 503 {
                throw GeminiError.temporarilyUnavailable
            }
            if statusCode == 429 {
                throw GeminiError.quotaExceeded
            }
            throw GeminiError.badResponse
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let text = decoded.candidates.first?.content.parts.first?.text ?? ""
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw GeminiError.emptyLyrics }
        let generated = LyricsResponseParser.parse(cleaned)
        print("Generated Gemini Lyrics:\n\(generated.lyrics)")
        return generated
    }

    private func performRequestWithRetry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let retryableStatusCodes = [429, 500, 502, 503, 504]
        var lastData = Data()
        var lastResponse: URLResponse?

        for attempt in 1...3 {
            let (data, response) = try await URLSession.shared.data(for: request)
            lastData = data
            lastResponse = response

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard retryableStatusCodes.contains(statusCode) else {
                return (data, response)
            }

            let responseBody = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("""
            Gemini retryable HTTP error:
            attempt=\(attempt)/3
            statusCode=\(statusCode)
            body=\(responseBody)
            """)

            if attempt < 3 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
            }
        }

        return (lastData, lastResponse ?? URLResponse())
    }

    enum GeminiError: LocalizedError {
        case missingAPIKey
        case badResponse
        case emptyLyrics
        case temporarilyUnavailable
        case quotaExceeded

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "Gemini API 키가 설정되지 않았습니다."
            case .badResponse:
                "Gemini 응답을 읽지 못했습니다."
            case .emptyLyrics:
                "Gemini가 가사를 반환하지 않았습니다."
            case .temporarilyUnavailable:
                "Gemini 사용량이 몰려 잠시 응답하지 않습니다. 잠시 후 다시 시도해 주세요."
            case .quotaExceeded:
                "Gemini 무료 사용량 또는 요청 한도를 초과했습니다."
            }
        }
    }
}

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

struct OpenAIService {
    // Add your OpenAI API key here when you are ready to use live lyric generation.
    // Example: var apiKey = "YOUR_OPENAI_API_KEY"
    var apiKey = ""
    var modelName = "gpt-4o-mini"    

    func generateLyrics(prompt: String) async throws -> GeneratedLyrics {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "YOUR_OPENAI_API_KEY" else {
            throw OpenAIError.missingAPIKey
        }

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw OpenAIError.badResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OpenAIRequest(
            model: modelName,
            instructions: """
            너는 한국어 알람송 제목과 가사를 만드는 작사가야.
            반드시 JSON만 출력해. 마크다운 코드블록, 설명, 주석은 출력하지 마.
            JSON 스키마: {"title":"노래 제목","lyrics":"가사"}
            title은 한국어 또는 짧은 영어로 30자 이내, lyrics는 한국어 알람송 가사만 200자 이내로 작성해.
            """,
            input: prompt
        ))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await performRequestWithRetry(request)
        } catch {
            print("OpenAI request failed: \(error.localizedDescription)")
            throw error
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("""
            OpenAI HTTP error:
            statusCode=\(statusCode)
            body=\(responseBody)
            """)
            if statusCode == 429 {
                throw OpenAIError.quotaExceeded
            }
            if [500, 502, 503, 504].contains(statusCode) {
                throw OpenAIError.temporarilyUnavailable
            }
            throw OpenAIError.badResponse
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let text = decoded.outputText ?? decoded.output
            .flatMap(\.content)
            .compactMap(\.text)
            .joined(separator: "\n")
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw OpenAIError.emptyLyrics }
        let generated = try LyricsResponseParser.parseOpenAI(cleaned)
        print("""
        Generated OpenAI Song:
        title=\(generated.title)
        lyrics=\(generated.lyrics)
        """)
        return generated
    }

    private func performRequestWithRetry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let retryableStatusCodes = [429, 500, 502, 503, 504]
        var lastData = Data()
        var lastResponse: URLResponse?

        for attempt in 1...3 {
            let (data, response) = try await URLSession.shared.data(for: request)
            lastData = data
            lastResponse = response

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard retryableStatusCodes.contains(statusCode) else {
                return (data, response)
            }

            let responseBody = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("""
            OpenAI retryable HTTP error:
            attempt=\(attempt)/3
            statusCode=\(statusCode)
            body=\(responseBody)
            """)

            if attempt < 3 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
            }
        }

        return (lastData, lastResponse ?? URLResponse())
    }

    enum OpenAIError: LocalizedError {
        case missingAPIKey
        case badResponse
        case emptyLyrics
        case temporarilyUnavailable
        case quotaExceeded

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "OpenAI API 키가 설정되지 않았습니다."
            case .badResponse:
                "OpenAI 응답을 읽지 못했습니다."
            case .emptyLyrics:
                "OpenAI가 가사를 반환하지 않았습니다."
            case .temporarilyUnavailable:
                "OpenAI 사용량이 몰려 잠시 응답하지 않습니다. 잠시 후 다시 시도해 주세요."
            case .quotaExceeded:
                "OpenAI 사용량 또는 요청 한도를 초과했습니다."
            }
        }
    }
}

private struct OpenAIRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
}

private struct OpenAIResponse: Decodable {
    let outputText: String?
    let output: [OpenAIOutput]

    private enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        outputText = try container.decodeIfPresent(String.self, forKey: .outputText)
        output = try container.decodeIfPresent([OpenAIOutput].self, forKey: .output) ?? []
    }
}

private struct OpenAIOutput: Decodable {
    let content: [OpenAIOutputContent]

    private enum CodingKeys: String, CodingKey {
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decodeIfPresent([OpenAIOutputContent].self, forKey: .content) ?? []
    }
}

private struct OpenAIOutputContent: Decodable {
    let text: String?
}

private struct GeneratedLyricsPayload: Decodable {
    let title: String
    let lyrics: String
}

private enum LyricsResponseParser {
    static func parseOpenAI(_ text: String) throws -> GeneratedLyrics {
        let jsonText = stripMarkdownFence(text)
        guard let data = jsonText.data(using: .utf8),
              let payload = try? JSONDecoder().decode(GeneratedLyricsPayload.self, from: data) else {
            throw OpenAIService.OpenAIError.badResponse
        }
        return clean(title: payload.title, lyrics: payload.lyrics)
    }

    static func parse(_ text: String) -> GeneratedLyrics {
        let jsonText = stripMarkdownFence(text)
        if let data = jsonText.data(using: .utf8),
           let payload = try? JSONDecoder().decode(GeneratedLyricsPayload.self, from: data) {
            return clean(title: payload.title, lyrics: payload.lyrics)
        }
        return clean(title: "Wakey Alarm Song", lyrics: text)
    }

    private static func stripMarkdownFence(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }

    private static func clean(title: String, lyrics: String) -> GeneratedLyrics {
        let cleanedTitle = title
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedLyrics = lyrics.trimmingCharacters(in: .whitespacesAndNewlines)
        return GeneratedLyrics(
            title: String((cleanedTitle.isEmpty ? "Wakey Alarm Song" : cleanedTitle).prefix(30)),
            lyrics: String(cleanedLyrics.prefix(200))
        )
    }
}

enum LyricsProvider {
    case openAI
    case gemini
}

struct LyricsGenerator {
    private let provider: LyricsProvider = .openAI
    private let openAIService = OpenAIService()
    private let geminiService = GeminiService()

    func generate(
        draft: AlarmDraft,
        alarmDate: Date,
        locationSummary: String?,
        weatherSummary: String?,
        calendarSummary: String?
    ) async throws -> GeneratedLyrics {
        let prompt = lyricsPrompt(
            draft: draft,
            alarmDate: alarmDate,
            locationSummary: locationSummary,
            weatherSummary: weatherSummary,
            calendarSummary: calendarSummary
        )

        switch provider {
        case .openAI:
            return try await openAIService.generateLyrics(prompt: prompt)
        case .gemini:
            return try await geminiService.generateLyrics(prompt: prompt)
        }
    }

    func lyricsPrompt(
        draft: AlarmDraft,
        alarmDate: Date,
        locationSummary: String?,
        weatherSummary: String?,
        calendarSummary: String?
    ) -> String {
        var requirements = [
            "너는 사람을 노래로 깨워주는 인간이야. 노래 제목과 한국어 알람송 가사를 만들어줘.",
            "응답은 반드시 JSON 하나만 출력해줘. 형식은 {\"title\":\"노래 제목\",\"lyrics\":\"가사\"}.",
            "title은 30자 이내로 작성하되 알람송의 제목이라는 프레임에 갇히지 말고 진짜 노래 제목같은 title로 작성해줘, lyrics는 200자 이내로 작성해주고 문장마다 줄바꿈 문자를 넣어줘.",
            "알람이 울리는 날짜 '\(alarmDate.koreanFullDateText)'를 자연스럽게 포함해줘.",
            "노래 분위기는 '\(draft.mood.rawValue)' 스타일로 맞춰줘."
        ]

        let nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nickname.isEmpty {
            requirements.append("부를 이름 '\(nickname)'을 포함해줘.")
        }

        if draft.purpose != .other {
            requirements.append("알람 목적 '\(draft.purpose.rawValue)'을 포함해줘.")
        }

        let memo = draft.memo.trimmingCharacters(in: .whitespacesAndNewlines)
        if !memo.isEmpty {
            requirements.append("메모 정보 '\(memo)'를 포함해줘.")
        }

        if let weatherSummary {
            requirements.append("날씨 정보 '\(weatherSummary)'를 포함해줘.")
        }

        if let locationSummary {
            requirements.append("위치 정보 '\(locationSummary)'를 포함해줘.")
        }

        if let calendarSummary {
            requirements.append("캘린더 일정 '\(calendarSummary)'을 포함해줘.")
        }

        requirements.append("위치 정보는 동네 이름까지만 언급해주고 각 요소들을 단순 나열 하는게 아니라 이야기처럼 자연스럽게 연결되게 해줘.")
        requirements.append("JSON 외의 설명 문장은 절대 출력하지 마.")
        print("Generated Lyrics Prompt:\n\(requirements.joined(separator: "\n"))")
        return requirements.joined(separator: "\n")
    }

    private func fallbackLyrics(
        draft: AlarmDraft,
        alarmDate: Date,
        locationSummary: String?,
        weatherSummary: String?,
        calendarSummary: String?
    ) -> String {
        var parts: [String] = [alarmDate.koreanFullDateText]
        let nickname = draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nickname.isEmpty {
            parts.append("\(nickname)아")
        }
        if draft.purpose != .other {
            parts.append("\(draft.purpose.rawValue) 시간")
        }
        if !draft.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(draft.memo.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let weatherSummary {
            parts.append(weatherSummary)
        }
        if let locationSummary {
            parts.append(locationSummary)
        }
        if let calendarSummary {
            parts.append(calendarSummary)
        }
        parts.append("일어나 빛나는 하루를 시작해")
        return String(parts.joined(separator: ", ").prefix(100))
    }

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
