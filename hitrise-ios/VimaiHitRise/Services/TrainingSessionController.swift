import Combine
import Foundation

@MainActor
final class TrainingSessionController: ObservableObject {
    @Published private(set) var phase: TrainingPhase = .idle
    @Published private(set) var selectedMode: TrainingMode = .seconds30
    @Published private(set) var remainingSeconds: Int = 30
    @Published private(set) var totalHits: Int = 0
    @Published private(set) var peakForceN: Double = 0
    @Published private(set) var averageForceN: Double = 0
    @Published private(set) var latestForceN: Double = 0
    @Published private(set) var latestReport: TrainingReport?

    private var punchEvents: [PunchEvent] = []
    private var lastCounter: Int?
    private var trainingStart: Date?
    private var runTask: Task<TrainingReport?, Never>?

    var canStart: Bool {
        if case .idle = phase { return true }
        if case .finished = phase { return true }
        return false
    }

    func selectMode(_ mode: TrainingMode) {
        guard canStart else { return }
        selectedMode = mode
        remainingSeconds = mode.durationSeconds
    }

    func start(mode: TrainingMode) async -> TrainingReport? {
        guard canStart else { return nil }
        reset(mode: mode)
        runTask = Task { [weak self] in
            await self?.run(mode: mode)
        }
        return await runTask?.value
    }

    func stop() -> TrainingReport? {
        runTask?.cancel()
        runTask = nil
        guard case .running = phase else {
            phase = .idle
            return nil
        }
        return finish(mode: selectedMode, completed: false)
    }

    func ingest(_ telemetry: SensorBallTelemetry) {
        guard case .running = phase else { return }
        let counter = max(telemetry.hitCount, telemetry.pressureHitCount)
        defer { lastCounter = counter }
        guard let previous = lastCounter else {
            if telemetry.forceN > 0 {
                recordPunch(forceN: Double(telemetry.forceN), count: 1)
            }
            return
        }
        let delta = counterDelta(from: previous, to: counter)
        guard delta > 0 else {
            latestForceN = Double(telemetry.forceN)
            peakForceN = max(peakForceN, latestForceN)
            refreshAverageForce()
            return
        }
        recordPunch(forceN: Double(telemetry.forceN), count: delta)
    }

    private func run(mode: TrainingMode) async -> TrainingReport? {
        do {
            for value in [3, 2, 1] {
                phase = .countdown(value)
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
            trainingStart = Date()
            lastCounter = nil
            phase = .running
            for remaining in stride(from: mode.durationSeconds, through: 0, by: -1) {
                remainingSeconds = remaining
                if remaining > 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
            return finish(mode: mode, completed: true)
        } catch {
            phase = .idle
            return nil
        }
    }

    private func reset(mode: TrainingMode) {
        selectedMode = mode
        phase = .idle
        remainingSeconds = mode.durationSeconds
        totalHits = 0
        peakForceN = 0
        averageForceN = 0
        latestForceN = 0
        punchEvents.removeAll()
        lastCounter = nil
        trainingStart = nil
    }

    private func finish(mode: TrainingMode, completed: Bool) -> TrainingReport {
        let duration = max(1, Int(Date().timeIntervalSince(trainingStart ?? Date())))
        let effectiveDuration = completed ? mode.durationSeconds : min(mode.durationSeconds, duration)
        let frequency = Double(totalHits) / Double(max(1, effectiveDuration))
        let avgBpm = frequency * 60
        let calories = TrainingSessionController.caloriesForTraining(
            totalHits: totalHits,
            durationSeconds: effectiveDuration,
            avgForceN: averageForceN
        )
        let fat = calories / 7.7
        let burst = bestBurst()
        let ended = Int64(Date().timeIntervalSince1970 * 1000)
        let round = TrainingRoundReport(
            roundIndex: 1,
            totalRounds: 1,
            durationSeconds: effectiveDuration,
            totalHits: totalHits,
            caloriesBurned: calories,
            fatBurnedGrams: fat,
            peakForceN: peakForceN,
            avgForceN: averageForceN,
            avgBpm: avgBpm,
            rhythmAccuracy: 0,
            endedAtEpochMs: ended
        )
        let report = TrainingReport(
            id: UUID(),
            mode: mode,
            totalHits: totalHits,
            averageFrequency: frequency,
            bestBurstCount: burst.count,
            bestBurstStartSec: burst.start,
            endedAtEpochMs: ended,
            durationSeconds: effectiveDuration,
            completedRounds: 1,
            totalRounds: 1,
            caloriesBurned: calories,
            fatBurnedGrams: fat,
            avgBpm: avgBpm,
            peakForceN: peakForceN,
            avgForceN: averageForceN,
            roundReports: [round],
            playMode: mode.playMode,
            soundPackId: "sfx_gym"
        )
        latestReport = report
        phase = completed ? .finished : .idle
        return report
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
            punchEvents.append(PunchEvent(id: UUID(), forceN: forceN, timestamp: Date()))
        }
        totalHits += count
        latestForceN = forceN
        peakForceN = max(peakForceN, latestForceN)
        refreshAverageForce()
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
