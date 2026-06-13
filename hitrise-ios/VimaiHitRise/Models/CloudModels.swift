import Foundation

struct ActivationState: Codable {
    let serial: String
    let activationToken: String
    let installId: String
    let deviceHash: String
}

struct CloudUserProfile: Codable, Identifiable {
    var id: Int64 { userId }
    let userId: Int64
    let serial: String
    let serialMasked: String
    let nickname: String
    let languageCode: String
    let countryCode: String?
    let avatarColor: String
    let currentTier: Int
    let highestTier: Int
    let bestScoreCached: Int
    let best30HitsCached: Int
    let best60HitsCached: Int
    let bestBurstCached: Int
    let longestStreakCached: Int
    let activeDaysCached: Int
    let createdAt: String?
    let lastSeenAt: String?
}

struct CloudUserStatistics: Codable {
    let totalSessions: Int
    let totalHits: Int
    let best30Hits: Int
    let best60Hits: Int
    let average30Frequency: Double
    let average60Frequency: Double
    let personalBestHits: Int
    let bestBurstRecord: Int
    let bestAverageFrequency: Double
    let totalTrainingSeconds: Int
    let activeDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalCaloriesBurned: Double
    let totalFatBurnedGrams: Double
    let bestPeakForceN: Double
    let bestAvgForceN: Double
}

struct CloudRoundReportItem: Codable, Identifiable {
    var id: Int { roundIndex }
    let roundIndex: Int
    let totalRounds: Int
    let roundDurationSeconds: Int
    let cumulativeDurationSeconds: Int
    let roundHits: Int
    let cumulativeHits: Int
    let roundCaloriesBurned: Double
    let cumulativeCaloriesBurned: Double
    let roundFatBurnedGrams: Double
    let cumulativeFatBurnedGrams: Double
    let peakForceN: Double
    let avgForceN: Double
    let avgBpm: Double
    let rhythmAccuracy: Double
    let endedAt: String?
}

struct CloudTrainingHistoryItem: Codable, Identifiable {
    var id: Int64 { sessionId }
    let sessionId: Int64
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
    let playMode: String?
    let soundPackId: String?
    let roundReports: [CloudRoundReportItem]
    let startedAt: String?
    let endedAt: String?
}

struct CloudLeaderboardEntry: Codable, Identifiable {
    var id: Int64 { userId }
    let rank: Int
    let userId: Int64
    let nickname: String
    let serialMasked: String
    let countryCode: String?
    let tierLevel: Int
    let tierKey: String
    let bestHits: Int
    let scoreValue: Double
    let totalHits: Int
    let averageFrequency: Double
    let bestBurstCount: Int
    let bestBurstStartSec: Double
    let endedAt: String?
    let isMe: Bool
}

struct CloudBootstrapResponse: Codable {
    let status: String?
    let message: String?
    let reason: String?
    let profile: CloudUserProfile?
    let statistics: CloudUserStatistics?
    let history: [CloudTrainingHistoryItem]?
}

struct CloudSessionUploadResponse: Codable {
    let status: String?
    let message: String?
    let reason: String?
    let sessionId: Int64?
    let profile: CloudUserProfile?
    let statistics: CloudUserStatistics?
    let history: [CloudTrainingHistoryItem]?
}

struct CloudLeaderboardResponse: Codable {
    let status: String?
    let message: String?
    let reason: String?
    let boardKey: String?
    let modeSeconds: Int?
    let window: String?
    let top: [CloudLeaderboardEntry]?
    let me: CloudLeaderboardEntry?
}

struct CloudSoundAsset: Codable, Identifiable {
    let id: String
    let nameZh: String
    let nameEn: String
    let descriptionZh: String
    let descriptionEn: String
    let style: String
    let bpm: Int
    let durationMs: Int
    let url: URL
}

struct CloudSoundCatalog: Codable {
    let status: String?
    let message: String?
    let version: Int?
    let updatedAt: String?
    let items: [CloudSoundAsset]?
}
