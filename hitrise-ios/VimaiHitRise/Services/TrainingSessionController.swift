import Combine
import Foundation

@MainActor
final class TrainingSessionController: ObservableObject {
    @Published private(set) var phase: TrainingPhase = .idle
    @Published private(set) var selectedMode: TrainingMode = .seconds30
    @Published private(set) var selectedPlayMode: TrainingPlayMode = .classic30
    @Published private(set) var selectedSetup = TrainingSessionSetup()
    @Published private(set) var remainingSeconds: Int = 30
    @Published private(set) var totalHits: Int = 0
    @Published private(set) var peakForceN: Double = 0
    @Published private(set) var averageForceN: Double = 0
    @Published private(set) var latestForceN: Double = 0
    @Published private(set) var latestReport: TrainingReport?
    @Published private(set) var forceSamples: [Double] = []
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var totalRounds: Int = 1
    @Published private(set) var rhythmSummary = RhythmSummary()
    @Published private(set) var comboSummary: [String: Int] = [:]
    @Published private(set) var coachStatus: String = "待命"
    @Published private(set) var coachMessage: String = "连接 SENBALL 后开始训练，我会根据节奏和力度给你提示。"
    @Published private(set) var coachMeta: String = "AI 教练实时监听"

    private var punchEvents: [PunchEvent] = []
    private var lastCounter: Int?
    private var trainingStart: Date?
    private var currentRoundStart: Date?
    private var currentRoundStartHitIndex = 0
    private var completedRoundReports: [TrainingRoundReport] = []
    private var runTask: Task<TrainingReport?, Never>?
    private var activeRoundConfig: RoundConfig?
    private var activeSoundPackId = "sfx_gym"
    private var lastPunchDate: Date?

    var canStart: Bool {
        switch phase {
        case .idle, .finished, .error:
            return true
        case .countdown, .running, .resting:
            return false
        }
    }

    var progressFraction: Double {
        let duration = max(1, activeRoundConfig?.workSeconds ?? selectedMode.durationSeconds)
        return 1 - min(1, max(0, Double(remainingSeconds) / Double(duration)))
    }

    func selectMode(_ mode: TrainingMode) {
        guard canStart else { return }
        selectedMode = mode
        selectedPlayMode = TrainingPlayMode.allCases.first(where: { $0.baseMode == mode && !$0.isChallenge }) ?? .classic30
        remainingSeconds = mode.durationSeconds
    }

    func selectPlayMode(_ playMode: TrainingPlayMode) {
        guard canStart else { return }
        selectedPlayMode = playMode
        selectedMode = playMode.baseMode
        remainingSeconds = roundConfig(for: playMode, setup: selectedSetup).workSeconds
    }

    func updateSetup(_ setup: TrainingSessionSetup) {
        guard canStart else { return }
        selectedSetup = TrainingSessionSetup(
            workMinutes: setup.workMinutes.clamped(to: 1...10),
            restHalfMinutes: setup.restHalfMinutes.clamped(to: 0...10),
            rounds: setup.rounds.clamped(to: 1...10),
            rhythmMode: setup.rhythmMode,
            bpm: setup.bpm.clamped(to: 40...140)
        )
        remainingSeconds = roundConfig(for: selectedPlayMode, setup: selectedSetup).workSeconds
    }

    func start(mode: TrainingMode) async -> TrainingReport? {
        selectMode(mode)
        return await start(playMode: selectedPlayMode, setup: selectedSetup, soundPackId: activeSoundPackId)
    }

    func start(
        playMode: TrainingPlayMode,
        setup: TrainingSessionSetup,
        soundPackId: String
    ) async -> TrainingReport? {
        guard canStart else { return nil }
        let normalizedSetup = TrainingSessionSetup(
            workMinutes: setup.workMinutes.clamped(to: 1...10),
            restHalfMinutes: setup.restHalfMinutes.clamped(to: 0...10),
            rounds: setup.rounds.clamped(to: 1...10),
            rhythmMode: setup.rhythmMode,
            bpm: setup.bpm.clamped(to: 40...140)
        )
        selectedPlayMode = playMode
        selectedMode = playMode.baseMode
        selectedSetup = normalizedSetup
        activeSoundPackId = soundPackId.isEmpty ? "sfx_gym" : soundPackId
        let config = roundConfig(for: playMode, setup: normalizedSetup)
        reset(config: config)
        runTask = Task { [weak self] in
            guard let self else { return nil }
            return await self.run(playMode: playMode, config: config)
        }
        return await runTask?.value
    }

    func stop() -> TrainingReport? {
        runTask?.cancel()
        runTask = nil
        guard trainingStart != nil else {
            phase = .idle
            return nil
        }
        return finishSession(completed: false)
    }

    func ingest(_ telemetry: SensorBallTelemetry) {
        guard case .running = phase else { return }
        let counter = max(telemetry.hitCount, telemetry.pressureHitCount)
        defer { lastCounter = counter }
        let delta: Int
        if let previous = lastCounter {
            delta = counterDelta(from: previous, to: counter)
        } else {
            delta = telemetry.forceN > 0 ? 1 : 0
        }
        if delta > 0 {
            recordPunch(forceN: Double(telemetry.forceN), count: delta)
        } else {
            latestForceN = Double(telemetry.forceN)
            peakForceN = max(peakForceN, latestForceN)
            refreshAverageForce()
        }
    }

    private func run(playMode: TrainingPlayMode, config: RoundConfig) async -> TrainingReport? {
        do {
            pushCoach(status: "准备", message: "\(playMode.title) 即将开始", meta: "倒计时 3 秒")
            for value in [3, 2, 1] {
                phase = .countdown(value)
                remainingSeconds = value
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
            trainingStart = Date()
            for round in 1...config.rounds {
                currentRound = round
                currentRoundStart = Date()
                currentRoundStartHitIndex = punchEvents.count
                lastCounter = nil
                phase = .running
                pushCoach(
                    status: "实时监听",
                    message: "第 \(round)/\(config.rounds) 回合开始，保持出拳节奏。",
                    meta: selectedSetup.rhythmMode == .rhythm ? "\(selectedSetup.bpm) BPM 节奏训练" : "自由训练"
                )
                for remaining in stride(from: config.workSeconds, through: 0, by: -1) {
                    remainingSeconds = remaining
                    evaluateTimerCoachCue(remaining: remaining, total: config.workSeconds)
                    if remaining > 0 {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
                appendRoundReport(roundIndex: round, totalRounds: config.rounds, durationSeconds: config.workSeconds)
                if round < config.rounds && config.restSeconds > 0 {
                    for rest in stride(from: config.restSeconds, through: 0, by: -1) {
                        phase = .resting(round: round, seconds: rest)
                        remainingSeconds = rest
                        if rest == config.restSeconds {
                            pushCoach(status: "休息", message: "休息 \(config.restSeconds) 秒，下一回合继续。", meta: "第 \(round) 回合完成")
                        }
                        if rest > 0 {
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                    }
                }
            }
            return finishSession(completed: true)
        } catch {
            if Task.isCancelled {
                return nil
            }
            phase = .error(error.localizedDescription)
            pushCoach(status: "异常", message: error.localizedDescription, meta: "训练中断")
            return nil
        }
    }

    private func reset(config: RoundConfig) {
        activeRoundConfig = config
        phase = .idle
        remainingSeconds = config.workSeconds
        totalHits = 0
        peakForceN = 0
        averageForceN = 0
        latestForceN = 0
        forceSamples.removeAll()
        punchEvents.removeAll()
        completedRoundReports.removeAll()
        comboSummary.removeAll()
        rhythmSummary = RhythmSummary()
        lastCounter = nil
        lastPunchDate = nil
        trainingStart = nil
        currentRoundStart = nil
        currentRound = 1
        totalRounds = config.rounds
        coachStatus = "待命"
        coachMessage = "训练准备就绪。"
        coachMeta = config.label
    }

    private func roundConfig(for playMode: TrainingPlayMode, setup: TrainingSessionSetup) -> RoundConfig {
        switch playMode {
        case .levelChallenge, .dailyChallenge:
            return RoundConfig(id: playMode.apiValue, label: playMode.title, workSeconds: 30, restSeconds: 0, rounds: 1)
        case .classic30, .classic60, .burst10, .burst15:
            if setup.rounds > 1 || setup.restSeconds > 0 || setup.workSeconds != playMode.baseMode.durationSeconds {
                return setup.toRoundConfig()
            }
            return RoundConfig.forMode(playMode.baseMode)
        }
    }

    private func finishSession(completed: Bool) -> TrainingReport {
        if case .running = phase, let config = activeRoundConfig {
            let elapsed = max(1, Int(Date().timeIntervalSince(currentRoundStart ?? Date())))
            appendRoundReport(
                roundIndex: currentRound,
                totalRounds: config.rounds,
                durationSeconds: min(config.workSeconds, elapsed)
            )
        }
        let config = activeRoundConfig ?? RoundConfig.forMode(selectedMode)
        let effectiveDuration = max(1, completedRoundReports.map(\.durationSeconds).reduce(0, +))
        let frequency = Double(totalHits) / Double(effectiveDuration)
        let avgBpm = frequency * 60
        let calories = Self.caloriesForTraining(totalHits: totalHits, durationSeconds: effectiveDuration, avgForceN: averageForceN)
        let fat = calories / 7.7
        let burst = bestBurst()
        let ended = Int64(Date().timeIntervalSince1970 * 1000)
        let report = TrainingReport(
            id: UUID(),
            mode: selectedMode,
            totalHits: totalHits,
            averageFrequency: frequency,
            bestBurstCount: burst.count,
            bestBurstStartSec: burst.start,
            endedAtEpochMs: ended,
            durationSeconds: effectiveDuration,
            completedRounds: completedRoundReports.count,
            totalRounds: config.rounds,
            caloriesBurned: calories,
            fatBurnedGrams: fat,
            avgBpm: avgBpm,
            peakForceN: peakForceN,
            avgForceN: averageForceN,
            comboSummary: comboSummary,
            rhythmAccuracy: rhythmSummary.accuracy,
            rhythmSummary: rhythmSummary,
            roundConfig: config,
            roundReports: completedRoundReports,
            playMode: selectedPlayMode.apiValue,
            soundPackId: activeSoundPackId
        )
        latestReport = report
        phase = completed ? .finished : .idle
        pushCoach(
            status: completed ? "完成" : "已停止",
            message: "本次完成 \(totalHits) 拳，峰值 \(Int(peakForceN)) N。",
            meta: "平均 \(String(format: "%.2f", frequency))/s | \(String(format: "%.1f", calories)) kcal"
        )
        return report
    }

    private func appendRoundReport(roundIndex: Int, totalRounds: Int, durationSeconds: Int) {
        guard completedRoundReports.contains(where: { $0.roundIndex == roundIndex }) == false else { return }
        let roundEvents = Array(punchEvents.dropFirst(currentRoundStartHitIndex))
        let roundHits = roundEvents.count
        let roundPeak = roundEvents.map(\.forceN).max() ?? 0
        let roundAverage = roundEvents.isEmpty ? 0 : roundEvents.map(\.forceN).reduce(0, +) / Double(roundEvents.count)
        let calories = Self.caloriesForTraining(totalHits: roundHits, durationSeconds: durationSeconds, avgForceN: roundAverage)
        let report = TrainingRoundReport(
            roundIndex: roundIndex,
            totalRounds: totalRounds,
            durationSeconds: durationSeconds,
            totalHits: roundHits,
            caloriesBurned: calories,
            fatBurnedGrams: calories / 7.7,
            peakForceN: roundPeak,
            avgForceN: roundAverage,
            avgBpm: Double(roundHits) / Double(max(1, durationSeconds)) * 60,
            rhythmAccuracy: rhythmSummary.accuracy,
            endedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000)
        )
        completedRoundReports.append(report)
    }

    private func refreshAverageForce() {
        guard !punchEvents.isEmpty else {
            averageForceN = latestForceN
            return
        }
        averageForceN = punchEvents.map(\.forceN).reduce(0, +) / Double(punchEvents.count)
    }

    private func recordPunch(forceN: Double, count: Int) {
        for _ in 0..<count {
            let now = Date()
            let score = scoreBeat(at: now)
            punchEvents.append(PunchEvent(id: UUID(), forceN: forceN, timestamp: now, beatScore: score))
            updateCombo(now: now, forceN: forceN)
            lastPunchDate = now
        }
        totalHits += count
        latestForceN = forceN
        peakForceN = max(peakForceN, latestForceN)
        forceSamples.append(forceN)
        if forceSamples.count > 42 {
            forceSamples.removeFirst(forceSamples.count - 42)
        }
        refreshAverageForce()
        evaluatePunchCoachCue(forceN: forceN)
    }

    private func scoreBeat(at date: Date) -> BeatScore? {
        guard selectedSetup.rhythmMode == .rhythm, let start = currentRoundStart else { return nil }
        let beatInterval = 60.0 / Double(max(40, selectedSetup.bpm))
        let elapsed = date.timeIntervalSince(start)
        guard elapsed > 0.22 else { return nil }
        let nearestBeat = round(elapsed / beatInterval) * beatInterval
        let offset = abs(elapsed - nearestBeat)
        let score: BeatScore
        if offset <= 0.12 {
            rhythmSummary.perfectCount += 1
            score = .perfect
        } else if offset <= 0.24 {
            rhythmSummary.goodCount += 1
            score = .good
        } else {
            rhythmSummary.missCount += 1
            score = .miss
        }
        return score
    }

    private func updateCombo(now: Date, forceN: Double) {
        guard let previous = lastPunchDate else { return }
        let gap = now.timeIntervalSince(previous)
        if gap <= 0.45 {
            comboSummary["fast_combo", default: 0] += 1
            if totalHits > 0, totalHits.isMultiple(of: 16) {
                comboSummary["sixteen_chain", default: 0] += 1
            }
        }
        if forceN >= 180 {
            comboSummary["heavy_hit", default: 0] += 1
        }
    }

    private func evaluatePunchCoachCue(forceN: Double) {
        if totalHits > 0, totalHits.isMultiple(of: 20) {
            pushCoach(status: "节奏很好", message: "已经 \(totalHits) 拳，继续保持呼吸和脚步。", meta: "实时拳数提示")
        } else if forceN >= max(120, peakForceN * 0.96) {
            pushCoach(status: "重击", message: "这一拳很重，注意回弹后快速复位。", meta: "峰值 \(Int(forceN)) N")
        }
    }

    private func evaluateTimerCoachCue(remaining: Int, total: Int) {
        guard remaining > 0 else { return }
        if remaining == total / 2 {
            pushCoach(status: "中段", message: "训练过半，别急，稳定输出。", meta: "剩余 \(remaining) 秒")
        } else if remaining == 10 {
            pushCoach(status: "冲刺", message: "最后 10 秒，加速完成这一组。", meta: "倒计时冲刺")
        }
    }

    private func pushCoach(status: String, message: String, meta: String) {
        coachStatus = status
        coachMessage = message
        coachMeta = meta
    }

    private func counterDelta(from previous: Int, to current: Int) -> Int {
        if current >= previous {
            return current - previous
        }
        return (256 - previous) + current
    }

    private func bestBurst() -> (count: Int, start: Double) {
        guard let start = trainingStart, !punchEvents.isEmpty else {
            return (0, 0)
        }
        var bestCount = 0
        var bestStart = 0.0
        for event in punchEvents {
            let windowEnd = event.timestamp.addingTimeInterval(3)
            let count = punchEvents.filter { $0.timestamp >= event.timestamp && $0.timestamp <= windowEnd }.count
            if count > bestCount {
                bestCount = count
                bestStart = event.timestamp.timeIntervalSince(start)
            }
        }
        return (bestCount, bestStart)
    }

    nonisolated static func caloriesForTraining(totalHits: Int, durationSeconds: Int, avgForceN: Double) -> Double {
        let minutes = max(Double(durationSeconds) / 60.0, 0.1)
        let hitLoad = Double(totalHits) * 0.022
        let timeLoad = minutes * 4.6
        let forceBonus = min(max(avgForceN / 900.0, 0.0), 1.6) * Double(totalHits) * 0.006
        return max(0, (hitLoad + timeLoad + forceBonus) * 0.62)
    }
}

private extension TrainingPlayMode {
    var isChallenge: Bool {
        self == .levelChallenge || self == .dailyChallenge
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
