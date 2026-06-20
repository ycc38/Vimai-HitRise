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
    let totalRounds: Int?
    let bestRoundHits: Int?
    let averageRoundHits: Double?
    let bestRoundPeakForceN: Double?
    let bestRoundAvgForceN: Double?
    let averageRoundCaloriesBurned: Double?
}

struct CloudTierProgress: Codable {
    let level: Int
    let key: String
    let bestHits: Int
    let nextLevel: Int?
    let nextKey: String?
    let nextHits: Int?
    let progressHits: Int
    let progressTargetHits: Int

    var progressFraction: Double {
        guard progressTargetHits > 0 else { return 1 }
        return min(1, max(0, Double(progressHits) / Double(progressTargetHits)))
    }

    init(
        level: Int,
        key: String,
        bestHits: Int,
        nextLevel: Int?,
        nextKey: String?,
        nextHits: Int?,
        progressHits: Int,
        progressTargetHits: Int
    ) {
        self.level = level
        self.key = key
        self.bestHits = bestHits
        self.nextLevel = nextLevel
        self.nextKey = nextKey
        self.nextHits = nextHits
        self.progressHits = progressHits
        self.progressTargetHits = progressTargetHits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = container.decodeIntIfPresent(forKey: .level, default: 1)
        key = container.decodeStringIfPresent(forKey: .key, default: "rookie")
        bestHits = container.decodeIntIfPresent(forKey: .bestHits, default: 0)
        nextLevel = try container.decodeIfPresent(Int.self, forKey: .nextLevel)
        nextKey = try container.decodeIfPresent(String.self, forKey: .nextKey)
        nextHits = try container.decodeIfPresent(Int.self, forKey: .nextHits)
        progressHits = container.decodeIntIfPresent(forKey: .progressHits, default: bestHits)
        progressTargetHits = container.decodeIntIfPresent(forKey: .progressTargetHits, default: nextHits ?? max(bestHits, 1))
    }
}

struct CloudAchievementItem: Codable, Identifiable {
    var id: String { key }
    let key: String
    let metric: String
    let goal: Int
    let progress: Int
    let unlocked: Bool
    let unlockedAt: String?
    let sortOrder: Int

    var progressFraction: Double {
        guard goal > 0 else { return unlocked ? 1 : 0 }
        return min(1, max(0, Double(progress) / Double(goal)))
    }

    init(
        key: String,
        metric: String,
        goal: Int,
        progress: Int,
        unlocked: Bool,
        unlockedAt: String?,
        sortOrder: Int
    ) {
        self.key = key
        self.metric = metric
        self.goal = goal
        self.progress = progress
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = container.decodeStringIfPresent(forKey: .key, default: UUID().uuidString)
        metric = container.decodeStringIfPresent(forKey: .metric, default: "total_hits")
        goal = container.decodeIntIfPresent(forKey: .goal, default: 0)
        progress = container.decodeIntIfPresent(forKey: .progress, default: 0)
        unlocked = container.decodeBoolIfPresent(forKey: .unlocked, default: false)
        unlockedAt = try container.decodeIfPresent(String.self, forKey: .unlockedAt)
        sortOrder = container.decodeIntIfPresent(forKey: .sortOrder, default: 0)
    }
}

private extension KeyedDecodingContainer {
    func decodeStringIfPresent(forKey key: Key, default defaultValue: String) -> String {
        (try? decodeIfPresent(String.self, forKey: key)) ?? defaultValue
    }

    func decodeIntIfPresent(forKey key: Key, default defaultValue: Int) -> Int {
        (try? decodeIfPresent(Int.self, forKey: key)) ?? defaultValue
    }

    func decodeBoolIfPresent(forKey key: Key, default defaultValue: Bool) -> Bool {
        (try? decodeIfPresent(Bool.self, forKey: key)) ?? defaultValue
    }
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
    let achievements: [CloudAchievementItem]?
    let tier: CloudTierProgress?
    let promoted: Bool?
}

struct CloudSessionUploadResponse: Codable {
    let status: String?
    let message: String?
    let reason: String?
    let sessionId: Int64?
    let profile: CloudUserProfile?
    let statistics: CloudUserStatistics?
    let history: [CloudTrainingHistoryItem]?
    let achievements: [CloudAchievementItem]?
    let tier: CloudTierProgress?
    let promoted: Bool?
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

struct CloudSoundAsset: Codable, Identifiable, Equatable {
    let id: String
    let nameZh: String
    let nameEn: String
    let descriptionZh: String
    let descriptionEn: String
    let style: String
    let bpm: Int
    let durationMs: Int
    let url: URL

    var displayName: String { nameZh.isEmpty ? nameEn : nameZh }
    var displayDescription: String { descriptionZh.isEmpty ? descriptionEn : descriptionZh }
}

struct CloudSoundCatalog: Codable {
    let status: String?
    let message: String?
    let version: Int?
    let updatedAt: String?
    let items: [CloudSoundAsset]?
}
