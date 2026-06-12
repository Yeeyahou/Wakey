import Foundation

struct SunoGeneratedTrack {
    let title: String
    let audioURL: URL
}

struct SunoPollingUpdate {
    let taskId: String
    let attempt: Int
    let maxAttempts: Int
    let status: String
    let hasTrack: Bool
    let title: String?
    let audioURL: URL?
}

struct SunoService {
    enum SunoError: LocalizedError {
        case missingAPIKey
        case badResponse
        case taskFailed(String)
        case timedOut
        case noAudioURL

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "Suno API 키가 설정되지 않았습니다."
            case .badResponse:
                "Suno 응답을 읽지 못했습니다."
            case .taskFailed(let message):
                message
            case .timedOut:
                "음악 생성 시간이 초과되었습니다."
            case .noAudioURL:
                "생성된 오디오 URL을 찾지 못했습니다."
            }
        }
    }

    // Edit these values for your SunoAPI.org account/project.
    var baseURL = URL(string: "https://api.sunoapi.org")!
    var apiKey = "e74b1ca30b4a2aefcc5c6fc660c0e6c4"
    var generateEndpoint = "/api/v1/generate"
    var statusEndpoint = "/api/v1/generate/record-info"
    var callBackURL = "https://example.com/wakey-suno-callback"

    func generateSong(lyrics: String, mood: AlarmMood, title: String) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "YOUR_SUNO_API_KEY" else {
            throw SunoError.missingAPIKey
        }

        let url = baseURL.appending(path: generateEndpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = GenerateRequest(
            customMode: true,
            instrumental: false,
            model: "V4_5ALL",
            callBackUrl: callBackURL,
            prompt: lyrics,
            style: mood.sunoStylePrompt,
            title: title
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw SunoError.badResponse }
        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        guard decoded.code == 200, let taskId = decoded.data?.taskId else {
            throw SunoError.taskFailed(decoded.msg ?? "음악 생성 요청에 실패했습니다.")
        }
        print("Suno generate submitted: taskId=\(taskId), title=\(title)")
        return taskId
    }

    func pollUntilComplete(
        taskId: String,
        onUpdate: (@MainActor (SunoPollingUpdate) -> Void)? = nil
    ) async throws -> SunoGeneratedTrack {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, trimmedKey != "YOUR_SUNO_API_KEY" else {
            throw SunoError.missingAPIKey
        }

        var components = URLComponents(url: baseURL.appending(path: statusEndpoint), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "taskId", value: taskId)]
        guard let url = components?.url else { throw SunoError.badResponse }

        let maxAttempts = 12
        for attempt in 1...maxAttempts {
            try await Task.sleep(nanoseconds: 25_000_000_000)

            var request = URLRequest(url: url)
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw SunoError.badResponse }
            let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)

            guard decoded.code == 200 else {
                throw SunoError.taskFailed(decoded.msg ?? "음악 생성 상태 확인에 실패했습니다.")
            }

            let status = decoded.data?.status ?? decoded.data?.response?.status
            let track = decoded.firstTrack
            print("""
            Suno polling update:
            taskId=\(taskId)
            attempt=\(attempt)/\(maxAttempts)
            status=\(status ?? "UNKNOWN")
            title=\(track?.title ?? "-")
            audioURL=\(track?.audioURL.absoluteString ?? "-")
            """)
            await onUpdate?(SunoPollingUpdate(
                taskId: taskId,
                attempt: attempt,
                maxAttempts: maxAttempts,
                status: status ?? "UNKNOWN",
                hasTrack: track != nil,
                title: track?.title,
                audioURL: track?.audioURL
            ))

            if status == "SUCCESS", let track {
                return track
            }

            // TODO: If SunoAPI.org changes the response field from audioUrl,
            // adjust StatusResponse.firstTrack only.
            if let track {
                return track
            }

            if let status, Self.failedStatuses.contains(status) {
                throw SunoError.taskFailed("음악 생성에 실패했습니다.")
            }
        }

        throw SunoError.timedOut
    }

    func downloadAudio(from url: URL, alarmId: UUID) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw SunoError.badResponse }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documents.appendingPathComponent("alarm_\(alarmId.uuidString).mp3")
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    private static let failedStatuses: Set<String> = [
        "CREATE_TASK_FAILED",
        "GENERATE_AUDIO_FAILED",
        "SENSITIVE_WORD_ERROR"
    ]
}

private struct GenerateRequest: Encodable {
    let customMode: Bool
    let instrumental: Bool
    let model: String
    let callBackUrl: String
    let prompt: String
    let style: String
    let title: String
}

private struct GenerateResponse: Decodable {
    let code: Int
    let msg: String?
    let data: GenerateData?

    struct GenerateData: Decodable {
        let taskId: String?
    }
}

private struct StatusResponse: Decodable {
    let code: Int
    let msg: String?
    let data: StatusData?

    var firstTrack: SunoGeneratedTrack? {
        guard let sunoData = data?.response?.sunoData else { return nil }

        for item in sunoData {
            let audioURL = item.audioUrl.flatMap(URL.init(string:))
                ?? item.audio_url.flatMap(URL.init(string:))
                ?? item.sourceAudioUrl.flatMap(URL.init(string:))
            guard let audioURL else { continue }

            let trimmedTitle = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let title = trimmedTitle.isEmpty ? "Wakey Morning Song" : trimmedTitle

            return SunoGeneratedTrack(
                title: title,
                audioURL: audioURL
            )
        }

        return nil
    }

    struct StatusData: Decodable {
        let taskId: String?
        let status: String?
        let response: ResponseData?
    }

    struct ResponseData: Decodable {
        let taskId: String?
        let status: String?
        let sunoData: [SunoData]?
    }

    struct SunoData: Decodable {
        let audioUrl: String?
        let audio_url: String?
        let sourceAudioUrl: String?
        let title: String?
    }
}

extension AlarmMood {
    var sunoStylePrompt: String {
        switch self {
        case .exciting:
            "신나는 Korean morning alarm song, bright K-pop, upbeat drums, catchy short hook"
        case .soft:
            "잔잔한 Korean morning alarm song, soft acoustic pop, gentle vocal, warm melody"
        case .emotional:
            "감성적인 Korean morning alarm song, emotional ballad pop, warm vocal, inspiring morning mood"
        case .rock:
            "락 Korean morning alarm song, energetic pop rock, guitar riff, powerful vocal"
        }
    }
}
