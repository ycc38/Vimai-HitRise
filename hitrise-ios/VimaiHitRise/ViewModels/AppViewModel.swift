import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var profile: CloudUserProfile?
    @Published var statistics: CloudUserStatistics?
    @Published var history: [CloudTrainingHistoryItem] = []
    @Published var leaderboard: [CloudLeaderboardEntry] = []
    @Published var cloudMessage: String = "云端未同步"
    @Published var isCloudBusy = false
    @Published var selectedLeaderboardBoard = "total_hits"

    let ble = SensorBallBLEManager()
    let training = TrainingSessionController()
    let config = AppConfig.current

    private let api: HitRiseAPIClient
    private let identityStore = LocalIdentityStore()
    private var cancellables = Set<AnyCancellable>()
    private var trainingTask: Task<Void, Never>?

    var identity: ActivationState {
        identityStore.load()
    }

    init(api: HitRiseAPIClient = HitRiseAPIClient()) {
        self.api = api
        Publishers.MergeMany([
            ble.$bluetoothState.map { _ in () }.eraseToAnyPublisher(),
            ble.$devices.map { _ in () }.eraseToAnyPublisher(),
            ble.$connectedDevice.map { _ in () }.eraseToAnyPublisher(),
            ble.$statusMessage.map { _ in () }.eraseToAnyPublisher(),
            ble.$lastScanDebugText.map { _ in () }.eraseToAnyPublisher()
        ])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        training.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        ble.$latestTelemetry
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] telemetry in
                Task { @MainActor in
                    self?.training.ingest(telemetry)
                }
            }
            .store(in: &cancellables)
    }

    func bootstrap() async {
        await runCloudAction(label: "正在准备本机用户资料...") {
            let response = try await api.bootstrap(state: identity)
            applyBootstrap(response)
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            leaderboard = board.top ?? []
            cloudMessage = "云端已同步"
        }
    }

    func refreshCloudData() async {
        await runCloudAction(label: "正在刷新云端数据...") {
            let historyResponse = try await api.fetchHistory(state: identity)
            applyBootstrap(historyResponse)
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            leaderboard = board.top ?? []
            cloudMessage = "刷新完成"
        }
    }

    func startTraining() {
        guard training.canStart else { return }
        guard ble.connectedDevice != nil else {
            ble.statusMessage = "请先连接立式拳击速度球"
            return
        }
        trainingTask?.cancel()
        trainingTask = Task { [weak self] in
            guard let self else { return }
            _ = self.ble.setGyroscopeEnabled(true)
            let report = await self.training.start(mode: self.training.selectedMode)
            _ = self.ble.setGyroscopeEnabled(false)
            guard let report else { return }
            await self.upload(report: report)
        }
    }

    func stopTraining() {
        let report = training.stop()
        _ = ble.setGyroscopeEnabled(false)
        trainingTask?.cancel()
        trainingTask = nil
        if let report {
            Task { await upload(report: report) }
        }
    }

    func upload(report: TrainingReport) async {
        await runCloudAction(label: "正在上传训练报告...") {
            let response = try await api.uploadTrainingSession(state: identity, report: report)
            profile = response.profile ?? profile
            statistics = response.statistics ?? statistics
            history = response.history ?? history
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            leaderboard = board.top ?? leaderboard
            cloudMessage = "训练已上传"
        }
    }

    func changeLeaderboardBoard(_ key: String) {
        selectedLeaderboardBoard = key
        Task { await refreshLeaderboard() }
    }

    private func refreshLeaderboard() async {
        await runCloudAction(label: "正在刷新排行榜...") {
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            leaderboard = board.top ?? []
            cloudMessage = "排行榜已更新"
        }
    }

    private func runCloudAction(label: String, action: @MainActor () async throws -> Void) async {
        isCloudBusy = true
        cloudMessage = label
        do {
            try await action()
        } catch {
            cloudMessage = "云端失败：\(error.localizedDescription)"
        }
        isCloudBusy = false
    }

    private func applyBootstrap(_ response: CloudBootstrapResponse) {
        profile = response.profile ?? profile
        statistics = response.statistics ?? statistics
        history = response.history ?? history
    }
}
