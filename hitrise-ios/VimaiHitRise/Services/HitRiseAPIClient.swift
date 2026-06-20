import Foundation

final class HitRiseAPIClient {
    private let config: AppConfig
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: AppConfig = .current, session: URLSession = .shared) {
        self.config = config
        self.session = session
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func bootstrap(state: ActivationState) async throws -> CloudBootstrapResponse {
        try await post(
            path: "/api/v1/user/bootstrap",
            payload: AuthPayload(state: state, appVersion: config.appVersion, languageCode: "zh")
        )
    }

    func updateProfile(
        state: ActivationState,
        nickname: String,
        languageCode: String,
        avatarColor: String?
    ) async throws -> CloudBootstrapResponse {
        try await post(
            path: "/api/v1/user/profile/update",
            payload: ProfileUpdatePayload(
                state: state,
                appVersion: config.appVersion,
                nickname: nickname,
                languageCode: languageCode,
                avatarColor: avatarColor
            )
        )
    }

    func uploadTrainingSession(state: ActivationState, report: TrainingReport) async throws -> CloudSessionUploadResponse {
        let payload = TrainingSessionPayload(
            state: state,
            appVersion: config.appVersion,
            report: report
        )
        return try await post(path: "/api/v1/training/session", payload: payload)
    }

    func fetchHistory(state: ActivationState, limit: Int = 10) async throws -> CloudBootstrapResponse {
        try await post(
            path: "/api/v1/training/history",
            payload: HistoryPayload(state: state, appVersion: config.appVersion, limit: limit)
        )
    }

    func fetchLeaderboard(state: ActivationState, boardKey: String = "total_hits", limit: Int = 20) async throws -> CloudLeaderboardResponse {
        try await post(
            path: "/api/v1/leaderboard",
            payload: LeaderboardPayload(state: state, appVersion: config.appVersion, boardKey: boardKey, window: "all", limit: limit)
        )
    }

    func fetchSoundEffects() async throws -> CloudSoundCatalog {
        try await get(path: "/api/v1/sound-effects")
    }

    func fetchBackgroundMusic() async throws -> CloudSoundCatalog {
        try await get(path: "/api/v1/background-music")
    }

    private func post<T: Decodable, Payload: Encodable>(path: String, payload: Payload) async throws -> T {
        var request = URLRequest(url: url(path: path))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        return try await send(request)
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        var request = URLRequest(url: url(path: path))
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw APIError.server(message)
        }
        let decoded = try decoder.decode(T.self, from: data)
        if let status = decoded as? APIStatusReadable, status.apiStatus != "ok" {
            throw APIError.server(status.apiMessage ?? "Request failed")
        }
        return decoded
    }

    private func url(path: String) -> URL {
        let base = config.apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suffix = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/\(suffix)")!
    }
}

protocol APIStatusReadable {
    var apiStatus: String? { get }
    var apiMessage: String? { get }
}

extension CloudBootstrapResponse: APIStatusReadable {
    var apiStatus: String? { status }
    var apiMessage: String? { message }
}

extension CloudSessionUploadResponse: APIStatusReadable {
    var apiStatus: String? { status }
    var apiMessage: String? { message }
}

extension CloudLeaderboardResponse: APIStatusReadable {
    var apiStatus: String? { status }
    var apiMessage: String? { message }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "服务器响应无效"
        case .server(let message):
            return message
        }
    }
}

private struct AuthPayload: Encodable {
    let serial: String
    let activationToken: String
    let installId: String
    let deviceHash: String
    let appVersion: String
    let languageCode: String

    init(state: ActivationState, appVersion: String, languageCode: String) {
        serial = state.serial
        activationToken = state.activationToken
        installId = state.installId
        deviceHash = state.deviceHash
        self.appVersion = appVersion
        self.languageCode = languageCode
    }
}

private struct ProfileUpdatePayload: Encodable {
    let serial: String
    let activationToken: String
    let installId: String
    let deviceHash: String
    let appVersion: String
    let nickname: String
    let languageCode: String
    let avatarColor: String?

    init(state: ActivationState, appVersion: String, nickname: String, languageCode: String, avatarColor: String?) {
        serial = state.serial
        activationToken = state.activationToken
        installId = state.installId
        deviceHash = state.deviceHash
        self.appVersion = appVersion
        self.nickname = nickname
        self.languageCode = languageCode
        self.avatarColor = avatarColor
    }
}

private struct HistoryPayload: Encodable {
    let serial: String
    let activationToken: String
    let installId: String
    let deviceHash: String
    let appVersion: String
    let limit: Int

    init(state: ActivationState, appVersion: String, limit: Int) {
        serial = state.serial
        activationToken = state.activationToken
        installId = state.installId
        deviceHash = state.deviceHash
        self.appVersion = appVersion
        self.limit = limit
    }
}

private struct LeaderboardPayload: Encodable {
    let serial: String
    let activationToken: String
    let installId: String
    let deviceHash: String
    let appVersion: String
    let boardKey: String
    let window: String
    let limit: Int

    init(state: ActivationState, appVersion: String, boardKey: String, window: String, limit: Int) {
        serial = state.serial
        activationToken = state.activationToken
        installId = state.installId
        deviceHash = state.deviceHash
        self.appVersion = appVersion
        self.boardKey = boardKey
        self.window = window
        self.limit = limit
    }
}

private struct TrainingSessionPayload: Encodable {
    let serial: String
    let activationToken: String
    let installId: String
    let deviceHash: String
    let appVersion: String
    let modeSeconds: Int
    let durationSeconds: Int
    let totalHits: Int
    let averageFrequency: Double
    let bestBurstCount: Int
    let bestBurstStartSec: Double
    let caloriesBurned: Double
    let fatBurnedGrams: Double
    let avgBpm: Double
    let peakForceN: Double
    let avgForceN: Double
    let rhythmAccuracy: Double
    let comboSummaryJson: String
    let beatScoreCountsJson: String
    let roundConfigJson: String?
    let roundReportsJson: String
    let playMode: String
    let soundPackId: String
    let endedAtEpochMs: Int64

    init(state: ActivationState, appVersion: String, report: TrainingReport) {
        serial = state.serial
        activationToken = state.activationToken
        installId = state.installId
        deviceHash = state.deviceHash
        self.appVersion = appVersion
        modeSeconds = report.mode.durationSeconds
        durationSeconds = report.durationSeconds
        totalHits = report.totalHits
        averageFrequency = report.averageFrequency
        bestBurstCount = report.bestBurstCount
        bestBurstStartSec = report.bestBurstStartSec
        caloriesBurned = report.caloriesBurned
        fatBurnedGrams = report.fatBurnedGrams
        avgBpm = report.avgBpm
        peakForceN = report.peakForceN
        avgForceN = report.avgForceN
        rhythmAccuracy = report.rhythmAccuracy
        comboSummaryJson = Self.makeJsonObject(report.comboSummary)
        beatScoreCountsJson = Self.makeJsonObject([
            "perfect": report.rhythmSummary.perfectCount,
            "good": report.rhythmSummary.goodCount,
            "miss": report.rhythmSummary.missCount
        ])
        roundConfigJson = Self.makeRoundConfigJson(report.roundConfig)
        roundReportsJson = Self.makeRoundReportsJson(report.roundReports)
        playMode = report.playMode
        soundPackId = report.soundPackId
        endedAtEpochMs = report.endedAtEpochMs
    }

    private static func makeJsonObject(_ values: [String: Int]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: values),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    private static func makeRoundConfigJson(_ config: RoundConfig?) -> String? {
        guard let config else { return nil }
        let payload: [String: Any] = [
            "id": config.id,
            "label": config.label,
            "work_seconds": config.workSeconds,
            "rest_seconds": config.restSeconds,
            "rounds": config.rounds
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }

    private static func makeRoundReportsJson(_ rounds: [TrainingRoundReport]) -> String {
        let payload = rounds.map { round in
            [
                "round_index": round.roundIndex,
                "total_rounds": round.totalRounds,
                "duration_seconds": round.durationSeconds,
                "total_hits": round.totalHits,
                "calories_burned": round.caloriesBurned,
                "fat_burned_grams": round.fatBurnedGrams,
                "peak_force_n": round.peakForceN,
                "avg_force_n": round.avgForceN,
                "avg_bpm": round.avgBpm,
                "rhythm_accuracy": round.rhythmAccuracy,
                "ended_at_epoch_ms": round.endedAtEpochMs
            ] as [String: Any]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return text
    }
}
