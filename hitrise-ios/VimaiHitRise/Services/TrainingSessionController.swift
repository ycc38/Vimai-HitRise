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
    @Published private(set) var coachStatusText = LocalizedText("待命", "Standby", "En attente", "พร้อม")
    @Published private(set) var coachMessageText = LocalizedText(
        "连接 SENBALL 后开始训练，我会根据节奏和相对力量评分给你提示。",
        "Connect SENBALL to start training. I'll give cues based on your rhythm and relative power score.",
        "Connectez SENBALL pour commencer. Je vous guiderai selon votre rythme et votre score de puissance relative.",
        "เชื่อมต่อ SENBALL เพื่อเริ่มฝึก ฉันจะให้คำแนะนำตามจังหวะและคะแนนพลังสัมพัทธ์ของคุณ"
    )
    @Published private(set) var coachMetaText = LocalizedText("AI 教练实时监听", "AI coach listening live", "Coach IA à l'écoute", "โค้ช AI กำลังฟังแบบเรียลไทม์")

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

    var coachStatus: String { coachStatusText.text }
    var coachMessage: String { coachMessageText.text }
    var coachMeta: String { coachMetaText.text }

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
            bpm: setup.bpm.clamped(to: 100...300)
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
            bpm: setup.bpm.clamped(to: 100...300)
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
            let modeTitle = playMode.localizedTitle
            pushCoach(
                status: LocalizedText("准备", "Get ready", "Préparez-vous", "เตรียมตัว"),
                message: LocalizedText(
                    "\(modeTitle.zh) 即将开始",
                    "\(modeTitle.en) is about to start",
                    "\(modeTitle.fr) va commencer",
                    "\(modeTitle.th) กำลังจะเริ่ม"
                ),
                meta: LocalizedText("倒计时 3 秒", "3-second countdown", "Compte à rebours de 3 s", "นับถอยหลัง 3 วินาที")
            )
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
                let bpm = selectedSetup.bpm
                pushCoach(
                    status: LocalizedText("实时监听", "Listening", "Écoute", "กำลังฟัง"),
                    message: LocalizedText(
                        "第 \(round)/\(config.rounds) 回合开始，保持出拳节奏。",
                        "Round \(round)/\(config.rounds) starts. Keep your punching rhythm.",
                        "Round \(round)/\(config.rounds) : gardez votre rythme de frappe.",
                        "รอบ \(round)/\(config.rounds) เริ่มแล้ว รักษาจังหวะการออกหมัด"
                    ),
                    meta: selectedSetup.rhythmMode == .rhythm
                        ? LocalizedText("\(bpm) BPM 节奏训练", "\(bpm) BPM rhythm training", "Rythme \(bpm) BPM", "ฝึกจังหวะ \(bpm) BPM")
                        : LocalizedText("自由训练", "Free training", "Entraînement libre", "ฝึกอิสระ")
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
                            let restSeconds = config.restSeconds
                            pushCoach(
                                status: LocalizedText("休息", "Rest", "Repos", "พัก"),
                                message: LocalizedText(
                                    "休息 \(restSeconds) 秒，下一回合继续。",
                                    "Rest \(restSeconds) seconds, then the next round begins.",
                                    "Repos \(restSeconds) s, puis round suivant.",
                                    "พัก \(restSeconds) วินาที แล้วเริ่มรอบถัดไป"
                                ),
                                meta: LocalizedText("第 \(round) 回合完成", "Round \(round) complete", "Round \(round) terminé", "จบรอบที่ \(round)")
                            )
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
            let reason = error.localizedDescription
            pushCoach(
                status: LocalizedText("异常", "Error", "Erreur", "ผิดพลาด"),
                message: LocalizedText(reason, reason, reason, reason),
                meta: LocalizedText("训练中断", "Training interrupted", "Entraînement interrompu", "การฝึกถูกขัดจังหวะ")
            )
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
        coachStatusText = LocalizedText("待命", "Standby", "En attente", "พร้อม")
        coachMessageText = LocalizedText("训练准备就绪。", "Training is ready.", "L'entraînement est prêt.", "พร้อมเริ่มฝึกแล้ว")
        coachMetaText = config.localizedLabel
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
        let hits = totalHits
        let peak = Int(peakForceN)
        let frequencyText = String(format: "%.2f", frequency)
        let caloriesText = String(format: "%.1f", calories)
        pushCoach(
            status: completed
                ? LocalizedText("完成", "Done", "Terminé", "เสร็จแล้ว")
                : LocalizedText("已停止", "Stopped", "Arrêté", "หยุดแล้ว"),
            message: LocalizedText(
                "本次完成 \(hits) 拳，相对力量峰值评分 \(peak)。",
                "\(hits) punches this session, peak relative power score \(peak).",
                "\(hits) coups cette séance, score de puissance relative max. \(peak).",
                "ครั้งนี้ออกหมัด \(hits) ครั้ง คะแนนพลังสัมพัทธ์สูงสุด \(peak)"
            ),
            meta: LocalizedText(
                "平均 \(frequencyText)/s | \(caloriesText) kcal",
                "Avg \(frequencyText)/s | \(caloriesText) kcal",
                "Moy. \(frequencyText)/s | \(caloriesText) kcal",
                "เฉลี่ย \(frequencyText)/s | \(caloriesText) kcal"
            )
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
        let beatInterval = 60.0 / Double(selectedSetup.bpm.clamped(to: 100...300))
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
        if forceN >= 300 {
            comboSummary["heavy_hit", default: 0] += 1
        }
    }

    private func evaluatePunchCoachCue(forceN: Double) {
        if totalHits > 0, totalHits.isMultiple(of: 20) {
            let hits = totalHits
            pushCoach(
                status: LocalizedText("节奏很好", "Great rhythm", "Bon rythme", "จังหวะดีมาก"),
                message: LocalizedText(
                    "已经 \(hits) 拳，继续保持呼吸和脚步。",
                    "\(hits) punches so far. Keep your breathing and footwork steady.",
                    "Déjà \(hits) coups. Gardez votre respiration et vos appuis.",
                    "ออกหมัดแล้ว \(hits) ครั้ง รักษาการหายใจและฟุตเวิร์ก"
                ),
                meta: LocalizedText("实时拳数提示", "Live punch count", "Compteur de coups en direct", "จำนวนหมัดแบบเรียลไทม์")
            )
        } else if forceN >= max(200, peakForceN * 0.96) {
            let score = Int(forceN)
            pushCoach(
                status: LocalizedText("重击", "Heavy hit", "Coup puissant", "หมัดหนัก"),
                message: LocalizedText(
                    "这一拳的相对力量评分很高，注意回弹后快速复位。",
                    "High relative power score on that punch. Reset quickly after the rebound.",
                    "Score de puissance relative élevé. Revenez vite en garde après le rebond.",
                    "หมัดนี้คะแนนพลังสัมพัทธ์สูง รีบกลับท่าหลังลูกเด้งกลับ"
                ),
                meta: LocalizedText("峰值评分 \(score)", "Peak score \(score)", "Score max. \(score)", "คะแนนสูงสุด \(score)")
            )
        }
    }

    private func evaluateTimerCoachCue(remaining: Int, total: Int) {
        guard remaining > 0 else { return }
        if remaining == total / 2 {
            pushCoach(
                status: LocalizedText("中段", "Halfway", "Mi-parcours", "ครึ่งทาง"),
                message: LocalizedText(
                    "训练过半，别急，稳定输出。",
                    "Halfway there. Stay calm and keep a steady output.",
                    "À mi-parcours. Restez calme et régulier.",
                    "ผ่านครึ่งทางแล้ว ใจเย็นและออกหมัดให้สม่ำเสมอ"
                ),
                meta: LocalizedText("剩余 \(remaining) 秒", "\(remaining)s left", "\(remaining) s restantes", "เหลือ \(remaining) วินาที")
            )
        } else if remaining == 10 {
            pushCoach(
                status: LocalizedText("冲刺", "Sprint", "Sprint", "สปรินต์"),
                message: LocalizedText(
                    "最后 10 秒，加速完成这一组。",
                    "Final 10 seconds. Speed up and finish this set.",
                    "Dernières 10 secondes. Accélérez pour finir la série.",
                    "10 วินาทีสุดท้าย เร่งให้จบเซ็ตนี้"
                ),
                meta: LocalizedText("倒计时冲刺", "Final sprint", "Sprint final", "สปรินต์ช่วงท้าย")
            )
        }
    }

    private func pushCoach(status: LocalizedText, message: LocalizedText, meta: LocalizedText) {
        coachStatusText = status
        coachMessageText = message
        coachMetaText = meta
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
        // avgForceN is a legacy model name. It carries the unitless Relative Power Score.
        let powerBonus = min(max(avgForceN / 1500.0, 0.0), 1.6) * Double(totalHits) * 0.006
        return max(0, (hitLoad + timeLoad + powerBonus) * 0.62)
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
