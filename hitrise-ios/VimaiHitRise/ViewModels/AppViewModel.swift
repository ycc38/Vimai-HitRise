import AVFoundation
import Combine
import Foundation

enum CloudConsentState: String {
    case undecided
    case declined
    case accepted
}

@MainActor
final class AppViewModel: NSObject, ObservableObject {
    @Published var profile: CloudUserProfile?
    @Published var statistics: CloudUserStatistics?
    @Published var history: [CloudTrainingHistoryItem] = []
    @Published var leaderboard: [CloudLeaderboardEntry] = []
    @Published var leaderboardMe: CloudLeaderboardEntry?
    @Published var achievements: [CloudAchievementItem] = []
    @Published var tier: CloudTierProgress?
    @Published var cloudMessage: String = "云端未同步"
    @Published var isCloudBusy = false
    @Published var selectedLeaderboardBoard = "total_hits"
    @Published var selectedPaletteId = HitRisePalette.defaultId
    @Published var selectedLanguage = "zh"
    @Published var selectedSoundEffectId = "sfx_gym"
    @Published var selectedBackgroundMusicId = "none"
    @Published var soundEffects: [CloudSoundAsset] = []
    @Published var backgroundMusic: [CloudSoundAsset] = []
    @Published var audioMessage = "音频目录待同步"
    @Published var trainingLevel = 1
    @Published var trainingXP = 0
    @Published var trainingStreak = 0
    @Published var dailyTargetDone = false
    @Published var latestCoachOutcome: TrainingCoachOutcome?
    @Published private(set) var cloudConsentState: CloudConsentState = .undecided

    let ble = SensorBallBLEManager()
    let training = TrainingSessionController()
    let config = AppConfig.current

    private let api: HitRiseAPIClient
    private let identityStore = LocalIdentityStore()
    private var cancellables = Set<AnyCancellable>()
    private var trainingTask: Task<Void, Never>?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var previewPlayer: AVPlayer?
    private var effectPlayer: AVPlayer?
    private var backgroundPlayer: AVPlayer?
    private var lastTelemetryHitCounter: Int?
    private let defaults = UserDefaults.standard

    private enum FixedPreference {
        static let paletteId = HitRisePalette.defaultId
        static let soundEffectId = "sfx_gym"
        static let backgroundMusicId = "none"
    }

    var identity: ActivationState {
        identityStore.load()
    }

    var palette: HitRisePalette {
        HitRisePalette.byId(selectedPaletteId)
    }

    var hasCloudConsent: Bool {
        cloudConsentState == .accepted
    }

    var selectedSoundEffect: CloudSoundAsset? {
        soundEffects.first(where: { $0.id == selectedSoundEffectId })
    }

    var selectedBackgroundMusic: CloudSoundAsset? {
        backgroundMusic.first(where: { $0.id == selectedBackgroundMusicId })
    }

    var leaderboardBoards: [(String, String)] {
        [
            ("total_training_seconds", "训练时长"),
            ("total_hits", "累计拳数"),
            ("peak_force_n", "峰值力度"),
            ("avg_force_n", "平均力度"),
            ("calories_burned", "卡路里"),
            ("fat_burned_grams", "燃脂")
        ]
    }

    init(api: HitRiseAPIClient = HitRiseAPIClient()) {
        self.api = api
        super.init()
        loadLocalState()
        soundEffects = bundledSoundEffects()
        backgroundMusic = [CloudSoundAsset.noMusic]
        enforceFixedAppearanceAndAudioPreferences()
        wireObjectChanges()
        wireCoachSpeech()
    }

    func bootstrap() async {
        guard hasCloudConsent else {
            cloudMessage = "云端训练记录与排行榜未开启"
            return
        }
        await runCloudAction(label: "正在准备本机用户资料...") {
            let response = try await api.bootstrap(state: identity)
            applyBootstrap(response)
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            applyLeaderboard(board)
            cloudMessage = "云端已同步"
        }
        await refreshAudioCatalogs()
    }

    func setCloudConsent(_ allowed: Bool) {
        let nextState: CloudConsentState = allowed ? .accepted : .declined
        guard cloudConsentState != nextState else { return }

        cloudConsentState = nextState
        defaults.set(nextState.rawValue, forKey: Keys.cloudConsentState)

        if allowed {
            Task { await bootstrap() }
        } else {
            clearCloudData()
            cloudMessage = "云端训练记录与排行榜已关闭"
        }
    }

    func refreshCloudData() async {
        await runCloudAction(label: "正在刷新云端数据...") {
            let historyResponse = try await api.fetchHistory(state: identity)
            applyBootstrap(historyResponse)
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            applyLeaderboard(board)
            cloudMessage = "刷新完成"
        }
    }

    func refreshAudioCatalogs() async {
        do {
            let effects = try await api.fetchSoundEffects()
            soundEffects = effects.items?.ifEmpty(bundledSoundEffects()) ?? bundledSoundEffects()
            backgroundMusic = [CloudSoundAsset.noMusic]
            enforceFixedAppearanceAndAudioPreferences()
            audioMessage = "音频目录已同步"
            saveLocalState()
        } catch {
            soundEffects = bundledSoundEffects()
            backgroundMusic = [CloudSoundAsset.noMusic]
            enforceFixedAppearanceAndAudioPreferences()
            audioMessage = "云端音频不可用，使用内置目录"
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
            self.startBackgroundMusicIfNeeded()
            let report = await self.training.start(
                playMode: self.training.selectedPlayMode,
                setup: self.training.selectedSetup,
                soundPackId: self.selectedSoundEffectId
            )
            self.stopBackgroundMusic()
            _ = self.ble.setGyroscopeEnabled(false)
            guard let report else { return }
            self.applyTrainingOutcome(report: report)
            await self.upload(report: report)
        }
    }

    func stopTraining() {
        let report = training.stop()
        stopBackgroundMusic()
        _ = ble.setGyroscopeEnabled(false)
        trainingTask?.cancel()
        trainingTask = nil
        if let report {
            applyTrainingOutcome(report: report)
            Task { await upload(report: report) }
        }
    }

    func upload(report: TrainingReport) async {
        await runCloudAction(label: "正在上传训练报告...") {
            let response = try await api.uploadTrainingSession(state: identity, report: report)
            profile = response.profile ?? profile
            statistics = response.statistics ?? statistics
            history = response.history ?? history
            achievements = response.achievements ?? achievements
            tier = response.tier ?? tier
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            applyLeaderboard(board)
            cloudMessage = "训练已上传"
        }
    }

    func changeLeaderboardBoard(_ key: String) {
        selectedLeaderboardBoard = key
        Task { await refreshLeaderboard() }
    }

    func selectTrainingPlayMode(_ playMode: TrainingPlayMode) {
        training.selectPlayMode(playMode)
        saveLocalState()
    }

    func updateTrainingSetup(_ setup: TrainingSessionSetup) {
        training.updateSetup(setup)
        saveLocalState()
    }

    func updatePalette(_ id: String) {
        selectedPaletteId = FixedPreference.paletteId
        saveLocalState()
    }

    func updateLanguage(_ code: String) {
        selectedLanguage = code
        saveLocalState()
    }

    func selectSoundEffect(_ asset: CloudSoundAsset) {
        enforceFixedAppearanceAndAudioPreferences()
        saveLocalState()
    }

    func selectBackgroundMusic(_ asset: CloudSoundAsset) {
        selectedBackgroundMusicId = FixedPreference.backgroundMusicId
        stopBackgroundMusic()
        saveLocalState()
    }

    func previewAudio(_ asset: CloudSoundAsset) {
        previewPlayer?.pause()
        previewPlayer = AVPlayer(url: asset.url)
        previewPlayer?.play()
    }

    func stopAudioPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
    }

    func updateProfile(nickname: String, avatarColor: String) async {
        await runCloudAction(label: "正在更新个人资料...") {
            let response = try await api.updateProfile(
                state: identity,
                nickname: nickname,
                languageCode: selectedLanguage,
                avatarColor: avatarColor
            )
            applyBootstrap(response)
            cloudMessage = "个人资料已更新"
        }
    }

    func levelTargetHits() -> Int {
        18 + trainingLevel * 4
    }

    func dailyTargetHits() -> Int {
        max(30, (statistics?.best30Hits ?? 30) + 6)
    }

    private func refreshLeaderboard() async {
        await runCloudAction(label: "正在刷新排行榜...") {
            let board = try await api.fetchLeaderboard(state: identity, boardKey: selectedLeaderboardBoard)
            applyLeaderboard(board)
            cloudMessage = "排行榜已更新"
        }
    }

    private func runCloudAction(label: String, action: @MainActor () async throws -> Void) async {
        guard hasCloudConsent else {
            cloudMessage = "请先在设置中开启云端训练记录与排行榜"
            return
        }
        isCloudBusy = true
        cloudMessage = label
        do {
            try await action()
        } catch {
            cloudMessage = "云端失败：\(error.localizedDescription)"
        }
        isCloudBusy = false
    }

    private func clearCloudData() {
        profile = nil
        statistics = nil
        history = []
        leaderboard = []
        leaderboardMe = nil
        achievements = []
        tier = nil
        isCloudBusy = false
    }

    private func applyBootstrap(_ response: CloudBootstrapResponse) {
        profile = response.profile ?? profile
        statistics = response.statistics ?? statistics
        history = response.history ?? history
        achievements = response.achievements ?? achievements
        tier = response.tier ?? tier
    }

    private func applyLeaderboard(_ response: CloudLeaderboardResponse) {
        leaderboard = response.top ?? []
        leaderboardMe = response.me
    }

    private func applyTrainingOutcome(report: TrainingReport) {
        let target: Int?
        switch training.selectedPlayMode {
        case .levelChallenge:
            target = levelTargetHits()
        case .dailyChallenge:
            target = dailyTargetHits()
        default:
            target = nil
        }
        let met = target.map { report.totalHits >= $0 } ?? true
        let before = trainingLevel
        var xpGain = max(5, report.totalHits / 2)
        if met { xpGain += 20 }
        trainingXP += xpGain
        if training.selectedPlayMode == .levelChallenge, met {
            trainingLevel += 1
        }
        if training.selectedPlayMode == .dailyChallenge, met {
            dailyTargetDone = true
            trainingStreak += 1
        }
        latestCoachOutcome = TrainingCoachOutcome(
            playMode: training.selectedPlayMode,
            goalMet: met,
            levelBefore: before,
            levelAfter: trainingLevel,
            targetHits: target,
            streak: trainingStreak,
            xpGain: xpGain
        )
        saveLocalState()
    }

    private func wireObjectChanges() {
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
                    self?.playPunchEffectIfNeeded(telemetry)
                    self?.training.ingest(telemetry)
                }
            }
            .store(in: &cancellables)
    }

    private func wireCoachSpeech() {
        training.$coachMessage
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.speakCoach(message)
            }
            .store(in: &cancellables)
    }

    private func speakCoach(_ message: String) {
        if case .idle = training.phase {
            return
        }
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.48
        backgroundPlayer?.volume = 0.22
        speechSynthesizer.speak(utterance)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            Task { @MainActor in
                self?.backgroundPlayer?.volume = 0.72
            }
        }
    }

    private func startBackgroundMusicIfNeeded() {
        selectedBackgroundMusicId = FixedPreference.backgroundMusicId
        guard selectedBackgroundMusicId != "none",
              let asset = selectedBackgroundMusic else { return }
        backgroundPlayer = AVPlayer(url: asset.url)
        backgroundPlayer?.volume = 0.72
        backgroundPlayer?.play()
    }

    private func stopBackgroundMusic() {
        backgroundPlayer?.pause()
        backgroundPlayer = nil
    }

    private func playPunchEffectIfNeeded(_ telemetry: SensorBallTelemetry) {
        let counter = max(telemetry.hitCount, telemetry.pressureHitCount)
        defer { lastTelemetryHitCounter = counter }
        guard let previous = lastTelemetryHitCounter else { return }
        let delta = counter >= previous ? counter - previous : counter + 256 - previous
        guard delta > 0, let asset = selectedSoundEffect else { return }
        effectPlayer = AVPlayer(url: asset.url)
        effectPlayer?.volume = 0.85
        effectPlayer?.play()
    }

    private func loadLocalState() {
        cloudConsentState = defaults.string(forKey: Keys.cloudConsentState)
            .flatMap(CloudConsentState.init(rawValue:)) ?? .undecided
        selectedPaletteId = FixedPreference.paletteId
        selectedLanguage = defaults.string(forKey: Keys.language) ?? "zh"
        selectedSoundEffectId = FixedPreference.soundEffectId
        selectedBackgroundMusicId = FixedPreference.backgroundMusicId
        trainingLevel = max(1, defaults.integer(forKey: Keys.trainingLevel))
        if trainingLevel == 1, defaults.object(forKey: Keys.trainingLevel) == nil {
            trainingLevel = 1
        }
        trainingXP = defaults.integer(forKey: Keys.trainingXP)
        trainingStreak = defaults.integer(forKey: Keys.trainingStreak)
        dailyTargetDone = defaults.bool(forKey: Keys.dailyTargetDone)
        if let data = defaults.data(forKey: Keys.trainingSetup),
           let setup = try? JSONDecoder().decode(TrainingSessionSetup.self, from: data) {
            training.updateSetup(setup)
        }
    }

    private func saveLocalState() {
        enforceFixedAppearanceAndAudioPreferences()
        defaults.set(selectedPaletteId, forKey: Keys.paletteId)
        defaults.set(selectedLanguage, forKey: Keys.language)
        defaults.set(selectedSoundEffectId, forKey: Keys.soundEffectId)
        defaults.set(selectedBackgroundMusicId, forKey: Keys.backgroundMusicId)
        defaults.set(trainingLevel, forKey: Keys.trainingLevel)
        defaults.set(trainingXP, forKey: Keys.trainingXP)
        defaults.set(trainingStreak, forKey: Keys.trainingStreak)
        defaults.set(dailyTargetDone, forKey: Keys.dailyTargetDone)
        if let data = try? JSONEncoder().encode(training.selectedSetup) {
            defaults.set(data, forKey: Keys.trainingSetup)
        }
    }

    private func bundledSoundEffects() -> [CloudSoundAsset] {
        CloudSoundAsset.fallbackEffects(baseURL: config.apiBaseURL)
    }

    private func bundledBackgroundMusic() -> [CloudSoundAsset] {
        CloudSoundAsset.fallbackMusic(baseURL: config.apiBaseURL)
    }

    private func enforceFixedAppearanceAndAudioPreferences() {
        selectedPaletteId = FixedPreference.paletteId
        if soundEffects.noneMatch(id: FixedPreference.soundEffectId) {
            selectedSoundEffectId = soundEffects.first?.id ?? FixedPreference.soundEffectId
        } else {
            selectedSoundEffectId = FixedPreference.soundEffectId
        }
        selectedBackgroundMusicId = FixedPreference.backgroundMusicId
    }

    private enum Keys {
        static let paletteId = "hitrise.palette.id"
        static let language = "hitrise.language"
        static let soundEffectId = "hitrise.sound.effect.id"
        static let backgroundMusicId = "hitrise.background.music.id"
        static let trainingLevel = "hitrise.training.level"
        static let trainingXP = "hitrise.training.xp"
        static let trainingStreak = "hitrise.training.streak"
        static let dailyTargetDone = "hitrise.daily.target.done"
        static let trainingSetup = "hitrise.training.setup"
        static let cloudConsentState = "hitrise.cloud.training.consent"
    }
}

private extension Array where Element == CloudSoundAsset {
    func noneMatch(id: String) -> Bool {
        !contains(where: { $0.id == id })
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}

extension CloudSoundAsset {
    static let noMusic = CloudSoundAsset(
        id: "none",
        nameZh: "不播放背景音乐",
        nameEn: "No background music",
        descriptionZh: "只保留拳击音效和 AI 教练提示。",
        descriptionEn: "Only punch effects and AI coach cues.",
        style: "none",
        bpm: 0,
        durationMs: 0,
        url: URL(string: "about:blank")!
    )

    static func fallbackEffects(baseURL: URL) -> [CloudSoundAsset] {
        [
            asset(id: "sfx_gym", zh: "拳馆雷鸣", en: "Arena thunder", file: "01_htr_punch_arena_thunder.wav", baseURL: baseURL),
            asset(id: "sfx_street", zh: "街头火花", en: "Street spark", file: "02_htr_punch_street_spark.wav", baseURL: baseURL),
            asset(id: "sfx_iron", zh: "铁拳钩击", en: "Iron hook", file: "03_htr_punch_iron_hook.wav", baseURL: baseURL),
            asset(id: "sfx_neon", zh: "霓虹刺拳", en: "Neon jab", file: "04_htr_punch_neon_jab.wav", baseURL: baseURL),
            asset(id: "sfx_bass", zh: "低频重击", en: "Bass smash", file: "05_htr_punch_bass_smash.wav", baseURL: baseURL)
        ]
    }

    static func fallbackMusic(baseURL: URL) -> [CloudSoundAsset] {
        [
            music(id: "music_champion", zh: "冠军冲刺", en: "Champion rush", file: "01_htr_music_champion_rush.wav", baseURL: baseURL),
            music(id: "music_voltage", zh: "擂台电压", en: "Ring voltage", file: "02_htr_music_ring_voltage.wav", baseURL: baseURL),
            music(id: "music_ignite", zh: "街头点燃", en: "Street ignite", file: "03_htr_music_street_ignite.wav", baseURL: baseURL),
            music(id: "music_drive", zh: "钢铁推进", en: "Iron drive", file: "04_htr_music_iron_drive.wav", baseURL: baseURL),
            music(id: "music_combo", zh: "霓虹连击", en: "Neon combo", file: "05_htr_music_neon_combo.wav", baseURL: baseURL)
        ]
    }

    private static func asset(id: String, zh: String, en: String, file: String, baseURL: URL) -> CloudSoundAsset {
        CloudSoundAsset(id: id, nameZh: zh, nameEn: en, descriptionZh: "训练击打音效", descriptionEn: "Punch sound effect", style: "sfx", bpm: 0, durationMs: 800, url: assetURL(baseURL: baseURL, path: "assets/sfx/\(file)"))
    }

    private static func music(id: String, zh: String, en: String, file: String, baseURL: URL) -> CloudSoundAsset {
        CloudSoundAsset(id: id, nameZh: zh, nameEn: en, descriptionZh: "训练背景音乐", descriptionEn: "Training background music", style: "music", bpm: 90, durationMs: 60_000, url: assetURL(baseURL: baseURL, path: "assets/music/\(file)"))
    }

    private static func assetURL(baseURL: URL, path: String) -> URL {
        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)/\(path)") ?? baseURL
    }
}
