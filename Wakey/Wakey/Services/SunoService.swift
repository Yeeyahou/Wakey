import Foundation

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
    var apiKey = ""
    var generateEndpoint = "/api/v1/generate"
    var statusEndpoint = "/api/v1/generate/record-info"

    func generateSong(lyrics: String, mood: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SunoError.missingAPIKey
        }

        let url = baseURL.appending(path: generateEndpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = GenerateRequest(
            customMode: true,
            instrumental: false,
            model: "V4_5ALL",
            prompt: lyrics,
            style: "\(mood) Korean morning alarm song, bright pop, short hook",
            title: "Wakey Morning Song"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw SunoError.badResponse }
        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        guard decoded.code == 200, let taskId = decoded.data?.taskId else {
            throw SunoError.taskFailed(decoded.msg ?? "음악 생성 요청에 실패했습니다.")
        }
        return taskId
    }

    func pollUntilComplete(taskId: String) async throws -> URL {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SunoError.missingAPIKey
        }

        var components = URLComponents(url: baseURL.appending(path: statusEndpoint), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "taskId", value: taskId)]
        guard let url = components?.url else { throw SunoError.badResponse }

        for _ in 0..<12 {
            try await Task.sleep(nanoseconds: 25_000_000_000)

            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw SunoError.badResponse }
            let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)

            guard decoded.code == 200 else {
                throw SunoError.taskFailed(decoded.msg ?? "음악 생성 상태 확인에 실패했습니다.")
            }

            let status = decoded.data?.status ?? decoded.data?.response?.status
            if ["CREATE_TASK_FAILED", "GENERATE_AUDIO_FAILED", "CALLBACK_EXCEPTION", "SENSITIVE_WORD_ERROR"].contains(status) {
                throw SunoError.taskFailed("음악 생성에 실패했습니다.")
            }

            if status == "SUCCESS", let audioURL = decoded.firstAudioURL {
                return audioURL
            }

            // TODO: If SunoAPI.org changes the response field from audioUrl,
            // adjust StatusResponse.firstAudioURL only.
            if let audioURL = decoded.firstAudioURL {
                return audioURL
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
}

private struct GenerateRequest: Encodable {
    let customMode: Bool
    let instrumental: Bool
    let model: String
    let prompt: String
    let style: String
    let title: String

    // TODO: Add callBackUrl here if your SunoAPI.org plan requires callbacks.
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

    var firstAudioURL: URL? {
        data?.response?.sunoData?.compactMap { item in
            item.audioUrl.flatMap(URL.init(string:))
                ?? item.audio_url.flatMap(URL.init(string:))
                ?? item.sourceAudioUrl.flatMap(URL.init(string:))
        }.first
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
    }
}
