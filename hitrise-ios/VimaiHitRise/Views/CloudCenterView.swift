import Foundation
import SwiftUI

struct CloudCenterView: View {
    var body: some View {
        AchievementsHistoryView()
    }
}

struct AchievementsHistoryView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        let palette = app.palette
        ScrollView {
            VStack(spacing: 14) {
                tierHero(palette)
                achievementsGrid(palette)
                historyList(palette)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
        .refreshable {
            await app.refreshCloudData()
        }
    }

    private func tierHero(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: palette.isLight ? "#BDEFE6" : "#D4B16B", fill: palette.isLight ? "#FFFFFF" : "#0F1820") {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HitRiseBadge(text: "TIER \(app.tier?.level ?? app.profile?.currentTier ?? 1)", palette: palette, fill: palette.isLight ? "#DFFFF7" : "#D4B16B", textColor: palette.isLight ? "#096D65" : palette.buttonText)
                    Text(tierTitle)
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(hex: palette.textPrimary))
                    Text("累计最佳 30 秒 \(app.tier?.bestHits ?? app.statistics?.best30Hits ?? 0) 拳")
                        .font(.caption)
                        .foregroundStyle(Color(hex: palette.textSecondary))
                }
                Spacer()
                ShareLink(item: achievementsShareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: palette.accentHot))
                }
                .buttonStyle(.plain)
                Button {
                    Task { await app.refreshCloudData() }
                } label: {
                    Image(systemName: app.isCloudBusy ? "hourglass" : "arrow.clockwise")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: palette.accentHot))
                }
                .buttonStyle(.plain)
            }
            ProgressView(value: app.tier?.progressFraction ?? 0)
                .tint(Color(hex: palette.accentHot))
            Text(tierProgressText)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: palette.textMuted))
        }
    }

    private func achievementsGrid(_ palette: HitRisePalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HitRiseSectionTitle(title: "训练成就", subtitle: "解锁徽章，记录长期进步", palette: palette)
                Spacer()
                ShareLink(item: achievementsShareText) {
                    Text("分享荣誉")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: "#096D65"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color(hex: palette.isLight ? "#DFFFF7" : palette.cardAlt)))
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(app.achievements.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                    AchievementBadgeCard(item: item, palette: palette)
                }
                if app.achievements.isEmpty {
                    emptyState("暂无成就数据，刷新云端后显示。", palette: palette)
                }
            }
        }
    }

    private func historyList(_ palette: HitRisePalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HitRiseSectionTitle(title: "训练历史", subtitle: "最近云端训练记录", palette: palette)
            if app.history.isEmpty {
                emptyState("暂无云端训练记录。", palette: palette)
            } else {
                ForEach(app.history) { item in
                    HistorySessionCard(item: item, palette: palette)
                }
            }
        }
    }

    private func emptyState(_ text: String, palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette) {
            Text(text)
                .font(.caption)
                .foregroundStyle(Color(hex: palette.textMuted))
        }
    }

    private var tierTitle: String {
        if let next = app.tier?.nextLevel {
            return "向 TIER \(next) 冲刺"
        }
        return "最高段位已解锁"
    }

    private var tierProgressText: String {
        guard let tier = app.tier else { return app.cloudMessage }
        if let nextHits = tier.nextHits {
            return "\(tier.progressHits)/\(tier.progressTargetHits) | 下一段位 \(nextHits) 拳"
        }
        return "段位进度已完成"
    }

    private var achievementsShareText: String {
        let tier = app.tier?.level ?? app.profile?.currentTier ?? 1
        let unlocked = app.achievements.filter { $0.unlocked }.count
        let totalHits = app.statistics?.totalHits ?? app.history.first?.totalHits ?? 0
        return "我的智能拳击速度球荣誉：当前 TIER \(tier)，已解锁 \(unlocked) 个成就，累计 \(totalHits) 拳。"
    }
}

struct AchievementBadgeCard: View {
    let item: CloudAchievementItem
    let palette: HitRisePalette

    var body: some View {
        HitRiseCard(palette: palette, stroke: item.unlocked ? unlockedStroke : palette.stroke, fill: item.unlocked ? unlockedFill : palette.card, padding: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: item.unlocked ? accent : palette.cardAlt), Color(hex: palette.card)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(Color(hex: item.unlocked ? palette.accentHot : palette.stroke), lineWidth: 1))
                    Text(code)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: item.unlocked ? palette.textPrimary : palette.textMuted))
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 5) {
                    Text(name)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: palette.textPrimary))
                    ProgressView(value: item.progressFraction)
                        .tint(Color(hex: item.unlocked ? accent : palette.textMuted))
                    Text("\(item.progress)/\(item.goal)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(hex: palette.textMuted))
                }
            }
        }
    }

    private var code: String {
        if item.key.contains("duration") { return "TIME" }
        if item.key.contains("hits") { return "HIT" }
        if item.key.contains("force") { return "N" }
        if item.key.contains("calories") { return "KCAL" }
        if item.key.contains("fat") { return "FAT" }
        return "ACH"
    }

    private var name: String {
        item.key
            .replacingOccurrences(of: "_", with: " ")
            .uppercased()
    }

    private var accent: String {
        if item.key.contains("force") { return palette.forceHigh }
        if item.key.contains("calories") { return palette.warning }
        if item.key.contains("fat") { return "#00FFCC" }
        if item.key.contains("duration") { return palette.accent }
        return palette.accentHot
    }

    private var unlockedStroke: String {
        palette.isLight ? "#BDEFE6" : accent
    }

    private var unlockedFill: String {
        palette.isLight ? "#FFFFFF" : "#102230"
    }
}

struct HistorySessionCard: View {
    let item: CloudTrainingHistoryItem
    let palette: HitRisePalette

    var body: some View {
        HitRiseCard(palette: palette, stroke: palette.isLight ? "#BDEFE6" : "#20384A", fill: palette.card, padding: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(item.totalHits) 拳")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(hex: palette.accentHot))
                    Text(item.endedAt ?? item.startedAt ?? "云端训练")
                        .font(.caption)
                        .foregroundStyle(Color(hex: palette.textMuted))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.durationSeconds)s")
                    Text("\(String(format: "%.1f", item.caloriesBurned)) kcal")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: palette.textSecondary))
            }
            Text("峰值 \(Int(item.peakForceN)) N | 平均 \(Int(item.avgForceN)) N | 节奏 \(Int(item.rhythmAccuracy * 100))%")
                .font(.caption2)
                .foregroundStyle(Color(hex: palette.textMuted))
        }
    }
}

struct LeaderboardView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        let palette = app.palette
        ScrollView {
            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    HitRiseSectionTitle(title: "排行榜", subtitle: "查看不同维度的训练排名", palette: palette)
                    Spacer()
                    ShareLink(item: leaderboardShareText) {
                        Text("分享排名")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color(hex: "#096D65"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(hex: palette.isLight ? "#DFFFF7" : palette.cardAlt)))
                    }
                    .buttonStyle(.plain)
                }
                boardPicker(palette)
                podium(palette)
                if let me = app.leaderboardMe {
                    leaderboardMe(me, palette)
                }
                leaderboardList(palette)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
        .refreshable {
            await app.refreshCloudData()
        }
    }

    private func boardPicker(_ palette: HitRisePalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(app.leaderboardBoards, id: \.0) { board in
                    Button {
                        app.changeLeaderboardBoard(board.0)
                    } label: {
                        Text(board.1)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color(hex: app.selectedLeaderboardBoard == board.0 ? palette.buttonText : palette.textSecondary))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(Color(hex: app.selectedLeaderboardBoard == board.0 ? palette.accentHot : palette.cardAlt))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func podium(_ palette: HitRisePalette) -> some View {
        let top = Array(app.leaderboard.prefix(3))
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(top) { entry in
                HitRiseCard(palette: palette, stroke: podiumAccent(entry.rank, palette), fill: palette.isLight ? "#FFFFFF" : "#0D1924", padding: 12) {
                    Text("#\(entry.rank)")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color(hex: podiumAccent(entry.rank, palette)))
                    Text(entry.nickname)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: palette.textPrimary))
                        .lineLimit(1)
                    Text(scoreText(entry))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(hex: palette.textMuted))
                }
                .frame(maxWidth: .infinity)
            }
            if top.isEmpty {
                HitRiseCard(palette: palette) {
                    Text("暂无排行榜数据")
                        .foregroundStyle(Color(hex: palette.textMuted))
                }
            }
        }
    }

    private func leaderboardMe(_ entry: CloudLeaderboardEntry, _ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: palette.isLight ? "#BDEFE6" : "#2A5C7B", fill: palette.card) {
            HStack {
                VStack(alignment: .leading) {
                    Text("我的排名")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: palette.accentHot))
                    Text("#\(entry.rank) \(entry.nickname)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: palette.textPrimary))
                }
                Spacer()
                Text(scoreText(entry))
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(hex: palette.accentHot))
            }
        }
    }

    private func leaderboardList(_ palette: HitRisePalette) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(app.leaderboard.dropFirst(3))) { entry in
                HStack {
                    Text("#\(entry.rank)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: palette.textSecondary))
                        .frame(width: 48, alignment: .leading)
                    VStack(alignment: .leading) {
                        Text(entry.nickname)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(hex: palette.textPrimary))
                        Text(entry.serialMasked)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: palette.textMuted))
                    }
                    Spacer()
                    Text(scoreText(entry))
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color(hex: palette.accentHot))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: palette.card))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: palette.stroke), lineWidth: 1))
                )
            }
        }
    }

    private func podiumAccent(_ rank: Int, _ palette: HitRisePalette) -> String {
        switch rank {
        case 1: return "#FFD060"
        case 2: return "#DFFFF0"
        case 3: return "#E07010"
        default: return palette.accent
        }
    }

    private func scoreText(_ entry: CloudLeaderboardEntry) -> String {
        "\(Int(entry.scoreValue))"
    }

    private var leaderboardShareText: String {
        guard let me = app.leaderboardMe else {
            return "我正在挑战智能拳击速度球排行榜，来一起训练。"
        }
        return "我的智能拳击速度球排名：#\(me.rank) \(me.nickname)，成绩 \(scoreText(me))。"
    }
}

struct ProfileView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var showingEdit = false

    var body: some View {
        let palette = app.palette
        ScrollView {
            VStack(spacing: 14) {
                profileHero(palette)
                statsGrid(palette)
                actionPanel(palette)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)
        }
        .refreshable {
            await app.refreshCloudData()
        }
        .sheet(isPresented: $showingEdit) {
            EditProfileView()
                .environmentObject(app)
        }
    }

    private func profileHero(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: palette.isLight ? "#BDEFE6" : "#D9B870", fill: palette.isLight ? "#FFFFFF" : "#2C5B76") {
            HitRiseBadge(text: "HITRISE ATHLETE", palette: palette, fill: palette.isLight ? "#DFFFF7" : "#FFE8A8", textColor: palette.isLight ? "#096D65" : palette.buttonText)
            HStack(spacing: 16) {
                Text(profileInitial)
                    .font(.title.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 74, height: 74)
                    .background(Circle().fill(Color(hex: app.profile?.avatarColor ?? "#CC4400")))
                    .overlay(Circle().stroke(Color(hex: palette.accentHot), lineWidth: 2))
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.profile?.nickname ?? "拳击用户")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(hex: palette.textPrimary))
                    Text(app.profile?.serialMasked ?? app.identity.serial)
                        .font(.caption)
                        .foregroundStyle(Color(hex: palette.textMuted))
                    Text("TIER \(app.profile?.currentTier ?? app.tier?.level ?? 1) | 连续 \(app.statistics?.currentStreak ?? app.trainingStreak) 天")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: palette.accentHot))
                }
            }
            Text(app.cloudMessage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: palette.warning))
        }
    }

    private func statsGrid(_ palette: HitRisePalette) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            HitRiseMetricTile(title: "累计训练", value: "\(app.statistics?.totalSessions ?? 0)", unit: "次", palette: palette, accent: palette.accent)
            HitRiseMetricTile(title: "累计拳数", value: "\(app.statistics?.totalHits ?? 0)", unit: "拳", palette: palette, accent: palette.accentHot)
            HitRiseMetricTile(title: "最佳 30 秒", value: "\(app.statistics?.best30Hits ?? 0)", unit: "拳", palette: palette, accent: palette.success)
            HitRiseMetricTile(title: "峰值力度", value: "\(Int(app.statistics?.bestPeakForceN ?? 0))", unit: "N", palette: palette, accent: palette.forceHigh)
        }
    }

    private func actionPanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette) {
            HStack(spacing: 12) {
                HitRiseActionButton(title: "编辑资料", systemImage: "person.crop.circle", palette: palette, fill: "#16384A") {
                    showingEdit = true
                }
                HitRiseActionButton(title: "刷新云端", systemImage: "arrow.clockwise", palette: palette, fill: palette.accentHot) {
                    Task { await app.refreshCloudData() }
                }
            }
            Text("开发者：zclei@vip.sina.com")
                .font(.caption)
                .foregroundStyle(Color(hex: palette.textMuted))
        }
    }

    private var profileInitial: String {
        String((app.profile?.nickname ?? "R").prefix(1)).uppercased()
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var avatarColor = "#CC4400"
    private let colors = ["#CC4400", "#E07010", "#A73A54", "#FFD060", "#5C3D99", "#7A1400", "#8B5E3C", "#C06014"]

    var body: some View {
        let palette = app.palette
        NavigationStack {
            ZStack {
                Color(hex: palette.backgroundBottom).ignoresSafeArea()
                VStack(spacing: 16) {
                    HitRiseCard(palette: palette) {
                        TextField("昵称", text: $nickname)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(Color.white, lineWidth: avatarColor == color ? 3 : 0))
                                    .onTapGesture { avatarColor = color }
                            }
                        }
                    }
                    HitRiseActionButton(title: "保存", systemImage: "checkmark", palette: palette, fill: palette.accentHot) {
                        Task {
                            await app.updateProfile(nickname: nickname.isEmpty ? "拳击用户" : nickname, avatarColor: avatarColor)
                            dismiss()
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .onAppear {
            nickname = app.profile?.nickname ?? ""
            avatarColor = app.profile?.avatarColor ?? "#CC4400"
        }
        .preferredColorScheme(palette.isLight ? .light : .dark)
    }
}
