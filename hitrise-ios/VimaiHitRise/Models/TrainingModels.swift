import Foundation

/// UI language shared with models and services. `AppViewModel.selectedLanguage` keeps it in sync.
enum AppLanguage {
    static var code = "zh"

    static var speechVoiceCode: String {
        switch code {
        case "en": return "en-US"
        case "fr": return "fr-FR"
        case "th": return "th-TH"
        default: return "zh-CN"
        }
    }
}

func localizedText(_ zh: String, _ en: String, _ fr: String, _ th: String) -> String {
    switch AppLanguage.code {
    case "en": return en
    case "fr": return fr
    case "th": return th
    default: return zh
    }
}

/// Text kept in every language so stored status messages follow later language switches.
struct LocalizedText: Equatable {
    let zh: String
    let en: String
    let fr: String
    let th: String

    init(_ zh: String, _ en: String, _ fr: String, _ th: String) {
        self.zh = zh
        self.en = en
        self.fr = fr
        self.th = th
    }

    var text: String {
        localizedText(zh, en, fr, th)
    }
}

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

    var localizedTitle: LocalizedText {
        switch self {
        case .seconds30: return LocalizedText("30 秒", "30 sec", "30 s", "30 วินาที")
        case .seconds60: return LocalizedText("60 秒", "60 sec", "60 s", "60 วินาที")
        case .burst10: return LocalizedText("10 秒爆发", "10 sec burst", "Explosif 10 s", "ระเบิด 10 วิ")
        case .burst15: return LocalizedText("15 秒爆发", "15 sec burst", "Explosif 15 s", "ระเบิด 15 วิ")
        }
    }

    var title: String {
        localizedTitle.text
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

    var localizedTitle: LocalizedText {
        switch self {
        case .classic30: return LocalizedText("经典 30 秒", "Classic 30 sec", "Classique 30 s", "คลาสสิก 30 วินาที")
        case .classic60: return LocalizedText("经典 60 秒", "Classic 60 sec", "Classique 60 s", "คลาสสิก 60 วินาที")
        case .burst10: return LocalizedText("10 秒爆发", "10 sec burst", "Explosif 10 s", "ระเบิด 10 วิ")
        case .burst15: return LocalizedText("15 秒爆发", "15 sec burst", "Explosif 15 s", "ระเบิด 15 วิ")
        case .levelChallenge: return LocalizedText("关卡挑战", "Level Challenge", "Défi de niveau", "ท้าทายด่าน")
        case .dailyChallenge: return LocalizedText("每日挑战", "Daily Challenge", "Défi du jour", "ท้าทายประจำวัน")
        }
    }

    var title: String {
        localizedTitle.text
    }

    var subtitle: String {
        switch self {
        case .classic30: return localizedText("快速热身，稳定节奏。", "Quick warm-up with a steady rhythm.", "Échauffement rapide, rythme régulier.", "วอร์มอัพเร็ว รักษาจังหวะ")
        case .classic60: return localizedText("完整训练，观察耐力。", "A full session to test endurance.", "Séance complète pour tester l'endurance.", "ฝึกเต็มรอบ ดูความอึด")
        case .burst10: return localizedText("短时冲刺，追求爆发。", "Short sprint for explosive power.", "Sprint court pour l'explosivité.", "สปรินต์สั้น เน้นพลังระเบิด")
        case .burst15: return localizedText("延长冲刺，压榨速度。", "Longer sprint to push your speed.", "Sprint prolongé pour pousser la vitesse.", "สปรินต์ยาวขึ้น ดันความเร็ว")
        case .levelChallenge: return localizedText("达成目标后提升等级。", "Hit the target to level up.", "Atteignez l'objectif pour monter de niveau.", "ทำถึงเป้าเพื่อเลื่อนระดับ")
        case .dailyChallenge: return localizedText("完成今日目标，累积连续训练。", "Hit today's target to build your streak.", "Atteignez l'objectif du jour pour prolonger la série.", "ทำเป้าวันนี้ให้สำเร็จเพื่อสะสมสถิติต่อเนื่อง")
        }
    }
}

enum TrainingRhythmMode: String, CaseIterable, Identifiable, Codable {
    case free
    case rhythm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: return localizedText("自由", "Free", "Libre", "อิสระ")
        case .rhythm: return localizedText("节奏", "Rhythm", "Rythme", "จังหวะ")
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
        case .idle: return localizedText("准备训练", "Ready to train", "Prêt", "พร้อมฝึก")
        case .countdown(let value): return "\(value)"
        case .running: return localizedText("训练中", "Training", "Entraînement", "กำลังฝึก")
        case .resting: return localizedText("回合休息", "Round rest", "Repos", "พักระหว่างรอบ")
        case .finished: return localizedText("训练完成", "Training complete", "Entraînement terminé", "ฝึกเสร็จแล้ว")
        case .error: return localizedText("训练异常", "Training error", "Erreur d'entraînement", "การฝึกผิดพลาด")
        }
    }
}

struct TrainingSessionSetup: Codable, Equatable {
    var workMinutes: Int = 1
    var restHalfMinutes: Int = 1
    var rounds: Int = 3
    var rhythmMode: TrainingRhythmMode = .rhythm
    var bpm: Int = 100

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

    /// `label` is captured in the language active when the config was built; preset ids map back to their titles.
    var localizedLabel: LocalizedText {
        if let mode = TrainingMode(rawValue: id) {
            return mode.localizedTitle
        }
        if let playMode = TrainingPlayMode.allCases.first(where: { $0.apiValue == id }) {
            return playMode.localizedTitle
        }
        return LocalizedText(label, label, label, label)
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
        case 101: return localizedText("充电", "Charging", "En charge", "กำลังชาร์จ")
        case 102: return localizedText("充满", "Full", "Chargée", "เต็มแล้ว")
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
