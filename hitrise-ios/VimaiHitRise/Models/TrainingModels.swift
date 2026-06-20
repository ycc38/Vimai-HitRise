import Foundation

enum TrainingMode: String, CaseIterable, Identifiable, Codable {
    case seconds30
    case seconds60
    case burst10
    case burst15

    var id: String { rawValue }

    var durationSeconds: Int {
        switch self {
        case .seconds30: return 30
        case .seconds60: return 60
        case .burst10: return 10
        case .burst15: return 15
        }
    }

    var title: String {
        switch self {
        case .seconds30: return "30 秒"
        case .seconds60: return "60 秒"
        case .burst10: return "10 秒爆发"
        case .burst15: return "15 秒爆发"
        }
    }

    var playMode: String {
        switch self {
        case .seconds30: return "classic_30"
        case .seconds60: return "classic_60"
        case .burst10: return "burst_10"
        case .burst15: return "burst_15"
        }
    }
}

enum TrainingPlayMode: String, CaseIterable, Identifiable, Codable {
    case classic30
    case classic60
    case burst10
    case burst15
    case levelChallenge
    case dailyChallenge

    var id: String { rawValue }

    var baseMode: TrainingMode {
        switch self {
        case .classic30, .levelChallenge, .dailyChallenge:
            return .seconds30
        case .classic60:
            return .seconds60
        case .burst10:
            return .burst10
        case .burst15:
            return .burst15
        }
    }

    var apiValue: String {
        switch self {
        case .classic30: return "classic_30"
        case .classic60: return "classic_60"
        case .burst10: return "burst_10"
        case .burst15: return "burst_15"
        case .levelChallenge: return "level_challenge"
        case .dailyChallenge: return "daily_challenge"
        }
    }

    var title: String {
        switch self {
        case .classic30: return "经典 30 秒"
        case .classic60: return "经典 60 秒"
        case .burst10: return "10 秒爆发"
        case .burst15: return "15 秒爆发"
        case .levelChallenge: return "关卡挑战"
        case .dailyChallenge: return "每日挑战"
        }
    }

    var subtitle: String {
        switch self {
        case .classic30: return "快速热身，稳定节奏。"
        case .classic60: return "完整训练，观察耐力。"
        case .burst10: return "短时冲刺，追求爆发。"
        case .burst15: return "延长冲刺，压榨速度。"
        case .levelChallenge: return "达成目标后提升等级。"
        case .dailyChallenge: return "完成今日目标，累积连续训练。"
        }
    }
}

enum TrainingRhythmMode: String, CaseIterable, Identifiable, Codable {
    case free
    case rhythm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: return "自由"
        case .rhythm: return "节奏"
        }
    }
}

enum TrainingPhase: Equatable {
    case idle
    case countdown(Int)
    case running
    case resting(round: Int, seconds: Int)
    case finished
    case error(String)

    var title: String {
        switch self {
        case .idle: return "准备训练"
        case .countdown(let value): return "\(value)"
        case .running: return "训练中"
        case .resting: return "回合休息"
        case .finished: return "训练完成"
        case .error: return "训练异常"
        }
    }
}

struct TrainingSessionSetup: Codable, Equatable {
    var workMinutes: Int = 1
    var restHalfMinutes: Int = 1
    var rounds: Int = 3
    var rhythmMode: TrainingRhythmMode = .rhythm
    var bpm: Int = 80

    var workSeconds: Int { max(1, workMinutes) * 60 }
    var restSeconds: Int { max(0, restHalfMinutes) * 30 }
    var totalEstimatedSeconds: Int { (workSeconds + restSeconds) * max(1, rounds) }

    var label: String {
        "\(workMinutes)/\(Self.restHalfMinutesLabel(restHalfMinutes)) x \(rounds)"
    }

    func toRoundConfig() -> RoundConfig {
        RoundConfig(
            id: "custom_\(workMinutes)_\(restHalfMinutes)_\(rounds)",
            label: label,
            workSeconds: workSeconds,
            restSeconds: restSeconds,
            rounds: rounds
        )
    }

    static func restHalfMinutesLabel(_ value: Int) -> String {
        value.isMultiple(of: 2) ? "\(value / 2)" : String(format: "%.1f", Double(value) / 2.0)
    }
}

struct RoundConfig: Codable, Equatable {
    let id: String
    let label: String
    let workSeconds: Int
    let restSeconds: Int
    let rounds: Int

    static func forMode(_ mode: TrainingMode) -> RoundConfig {
        RoundConfig(id: mode.rawValue, label: mode.title, workSeconds: mode.durationSeconds, restSeconds: 0, rounds: 1)
    }
}

enum BeatScore: String, Codable {
    case perfect
    case good
    case miss
}

struct RhythmSummary: Codable, Equatable {
    var perfectCount: Int = 0
    var goodCount: Int = 0
    var missCount: Int = 0

    var totalJudged: Int {
        perfectCount + goodCount + missCount
    }

    var accuracy: Double {
        guard totalJudged > 0 else { return 0 }
        return (Double(perfectCount) + Double(goodCount) * 0.5) / Double(totalJudged)
    }
}

struct TrainingCoachOutcome: Codable, Equatable {
    let playMode: TrainingPlayMode
    let goalMet: Bool
    let levelBefore: Int
    let levelAfter: Int
    let targetHits: Int?
    let streak: Int
    let xpGain: Int
}

struct SensorBallDeviceInfo: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
    let isLikelySensorBall: Bool
    let detail: String

    init(id: UUID, name: String, rssi: Int, isLikelySensorBall: Bool = true, detail: String = "") {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.isLikelySensorBall = isLikelySensorBall
        self.detail = detail
    }
}

struct SensorBallTelemetry: Equatable {
    let packetIndex: Int
    let batteryRaw: Int
    let hitCount: Int
    let pressureHitCount: Int
    let gyroForceRaw: Int
    let pressureForceRaw: Int
    let forceLow: Int
    let forceHigh: Int
    let forceN: Int

    var batteryText: String {
        switch batteryRaw {
        case 101: return "充电"
        case 102: return "充满"
        case 0...100: return "\(batteryRaw)%"
        default: return "--"
        }
    }
}

struct PunchEvent: Identifiable, Codable {
    let id: UUID
    let forceN: Double
    let timestamp: Date
    let beatScore: BeatScore?
}

struct TrainingRoundReport: Identifiable, Codable {
    var id: Int { roundIndex }
    let roundIndex: Int
    let totalRounds: Int
    let durationSeconds: Int
    let totalHits: Int
    let caloriesBurned: Double
    let fatBurnedGrams: Double
    let peakForceN: Double
    let avgForceN: Double
    let avgBpm: Double
    let rhythmAccuracy: Double
    let endedAtEpochMs: Int64
}

struct TrainingReport: Identifiable, Codable {
    let id: UUID
    let mode: TrainingMode
    let totalHits: Int
    let averageFrequency: Double
    let bestBurstCount: Int
    let bestBurstStartSec: Double
    let endedAtEpochMs: Int64
    let durationSeconds: Int
    let completedRounds: Int
    let totalRounds: Int
    let caloriesBurned: Double
    let fatBurnedGrams: Double
    let avgBpm: Double
    let peakForceN: Double
    let avgForceN: Double
    let comboSummary: [String: Int]
    let rhythmAccuracy: Double
    let rhythmSummary: RhythmSummary
    let roundConfig: RoundConfig?
    let roundReports: [TrainingRoundReport]
    let playMode: String
    let soundPackId: String
}

extension TrainingReport {
    static func empty(mode: TrainingMode) -> TrainingReport {
        TrainingReport(
            id: UUID(),
            mode: mode,
            totalHits: 0,
            averageFrequency: 0,
            bestBurstCount: 0,
            bestBurstStartSec: 0,
            endedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            durationSeconds: mode.durationSeconds,
            completedRounds: 1,
            totalRounds: 1,
            caloriesBurned: 0,
            fatBurnedGrams: 0,
            avgBpm: 0,
            peakForceN: 0,
            avgForceN: 0,
            comboSummary: [:],
            rhythmAccuracy: 0,
            rhythmSummary: RhythmSummary(),
            roundConfig: RoundConfig.forMode(mode),
            roundReports: [],
            playMode: mode.playMode,
            soundPackId: "sfx_gym"
        )
    }
}
