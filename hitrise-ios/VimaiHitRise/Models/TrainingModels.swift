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

enum TrainingPhase: Equatable {
    case idle
    case countdown(Int)
    case running
    case finished
    case error(String)

    var title: String {
        switch self {
        case .idle: return "准备训练"
        case .countdown(let value): return "\(value)"
        case .running: return "训练中"
        case .finished: return "训练完成"
        case .error: return "训练异常"
        }
    }
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
            roundReports: [],
            playMode: mode.playMode,
            soundPackId: "sfx_gym"
        )
    }
}
