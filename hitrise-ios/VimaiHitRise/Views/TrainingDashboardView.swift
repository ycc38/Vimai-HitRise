import Foundation
import SwiftUI

struct TrainingDashboardView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var showingTrainingSettings = false
    var onSettings: (() -> Void)? = nil

    var body: some View {
        let palette = app.palette
        ScrollView {
            VStack(spacing: 14) {
                homeHeroCard(palette)
                trainingControlPanel(palette)
                homeForceCard(palette)
                homeConnectionReportCard(palette)
                homeGoalAchievementCard(palette)
                latestReportCard(palette)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingTrainingSettings) {
            TrainingSetupView()
                .environmentObject(app)
        }
    }

    private func trainingControlPanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: "#D6F2EC", fill: "#FFFFFF", padding: 14) {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Text("实时训练")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: "#17343B"))
                    Spacer(minLength: 8)
                    HitRiseBadge(
                        text: "第 \(app.training.currentRound) / \(app.training.totalRounds) 回合",
                        palette: palette,
                        fill: "#E4FFF9",
                        textColor: "#0A9D90"
                    )
                    Button {
                        showingTrainingSettings = true
                    } label: {
                        Label("训练设置", systemImage: "gearshape")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color(hex: "#17343B"))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(hex: "#F5FFFC")))
                            .overlay(Capsule().stroke(Color(hex: "#D6F2EC"), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                timerAndCount(palette)
                realtimeDashboard(palette)
                trainingProgressRow(palette)
                comboRecognitionRow(palette)
            }
            .background {
                trainingWatermark(palette)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func trainingWatermark(_ palette: HitRisePalette) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: palette.accent).opacity(0.18), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 2) {
                Image(systemName: "figure.boxing")
                    .font(.system(size: 76, weight: .black))
                Text("HITRISE")
                    .font(.system(size: 34, weight: .black, design: .rounded))
            }
            .foregroundStyle(Color(hex: palette.accentHot).opacity(0.11))
            .rotationEffect(.degrees(-12))
            .offset(x: 74, y: -18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .clipped()
    }

    private func homeHeroCard(_ palette: HitRisePalette) -> some View {
        ZStack(alignment: .topLeading) {
            Image("home_banner")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()
                .saturation(1.18)
                .contrast(1.06)

            VStack(alignment: .leading, spacing: 0) {
                Text("HitRise")
                    .font(.system(size: 26, weight: .black, design: .rounded).italic())
                    .foregroundStyle(Color(hex: "#17343B"))
                Text("家庭健身 · 燃脂拳击")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#4C7478"))
                    .padding(.top, 6)
                Text("10分钟\n轻松暴汗！")
                    .font(.system(size: 33, weight: .black, design: .rounded).italic())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#07A998"), Color(hex: "#050A0B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineSpacing(2)
                    .padding(.top, 36)
                Text("健身 | 减压 | 燃脂")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#17343B"))
                    .padding(.top, 58)
            }
            .padding(.leading, 24)
            .padding(.top, 24)

            Button {
                if let onSettings {
                    onSettings()
                } else {
                    showingTrainingSettings = true
                }
            } label: {
                Image("home_icon_settings")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.9)))
                    .overlay(Circle().stroke(Color(hex: "#CDEFE8"), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .padding(.top, 20)
            .padding(.trailing, 12)
        }
        .frame(height: 300)
        .background(Color(hex: "#E9FFFA"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#C8F0E8"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private func playModeGrid(_ palette: HitRisePalette) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(TrainingPlayMode.allCases) { mode in
                let selected = app.training.selectedPlayMode == mode
                Button {
                    app.selectTrainingPlayMode(mode)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.title)
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color(hex: selected ? selectedModeTextColor(palette) : palette.textPrimary))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(mode.subtitle)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: selected ? selectedModeTextColor(palette) : palette.textMuted).opacity(selected ? 0.82 : 1))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: selected ? palette.accentSoft : palette.cardAlt))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(hex: selected ? palette.accentHot : palette.stroke), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!app.training.canStart)
            }
        }
    }

    private func selectedModeTextColor(_ palette: HitRisePalette) -> String {
        palette.isLight ? "#096D65" : palette.buttonText
    }

    private func timerAndCount(_ palette: HitRisePalette) -> some View {
        HStack(spacing: 10) {
            roundActionButton(
                title: "开始",
                fill: "#20C8BA",
                disabled: !app.training.canStart
            ) {
                app.startTraining()
            }

            ZStack {
                Circle()
                    .fill(Color(hex: "#F8FFFD"))
                    .shadow(color: Color(hex: "#91E6D9").opacity(0.20), radius: 12, x: 0, y: 6)
                CircularTimerRing(
                    progress: app.training.progressFraction,
                    center: timeText,
                    caption: "回合时间",
                    palette: palette
                )
                .padding(9)
            }
            .frame(width: 126, height: 126)

            roundActionButton(
                title: "结束",
                fill: "#F6B986",
                disabled: app.training.canStart
            ) {
                app.stopTraining()
            }
        }
    }

    private func realtimeDashboard(_ palette: HitRisePalette) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            HomeMetricTile(iconName: "home_metric_hits", title: "拳数", value: reportHitsText, unit: "次", palette: palette, accent: "#17343B")
            HomeMetricTile(iconName: "home_metric_bpm", title: "BPM", value: bpmText, unit: "", palette: palette, accent: "#17343B")
            HomeMetricTile(iconName: "home_metric_calories", title: "卡路里", value: caloriesText, unit: "kcal", palette: palette, accent: "#17343B")
            HomeMetricTile(iconName: "home_metric_fat", title: "等效燃脂", value: fatText, unit: "g", palette: palette, accent: "#17343B")
        }
    }

    private func trainingProgressRow(_ palette: HitRisePalette) -> some View {
        HStack(spacing: 8) {
            Text("今日目标:")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "#557A7D"))
            Text("\(activeTargetHits) 拳")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
            Text("| 已完成 \(activeCompletedHits) 拳")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
            MiniProgressBar(progress: min(1, Double(activeCompletedHits) / Double(max(activeTargetHits, 1))))
                .frame(width: 104, height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comboRecognitionRow(_ palette: HitRisePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("连击识别")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    comboPill("重击", "\(comboValue("heavy_hit"))", fill: "#F5FFFC", stroke: "#CDEFE8", text: "#557A7D")
                    comboPill("速击", "\(comboValue("fast_combo"))", fill: "#DFFFF7", stroke: "#BCEFE6", text: "#0B9F91")
                    comboPill("三连击", nil, fill: "#F5FFFC", stroke: "#CDEFE8", text: "#557A7D")
                    comboPill("爆发连击", "\(app.training.latestReport?.bestBurstCount ?? app.training.comboSummary["sixteen_chain"] ?? 0)", fill: "#FF784B", stroke: "#FF784B", text: "#FFFFFF")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comboPill(_ title: String, _ value: String?, fill: String, stroke: String, text: String) -> some View {
        Text(value == nil ? title : "\(title) ×\(value ?? "0")")
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(Color(hex: text))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color(hex: fill)))
            .overlay(Capsule().stroke(Color(hex: stroke), lineWidth: 1))
    }

    private func roundActionButton(title: String, fill: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(Color.white)
                .frame(width: 64, height: 48)
                .background(Capsule().fill(Color(hex: fill)))
                .shadow(color: Color(hex: fill).opacity(0.22), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1)
    }

    private func homeForceCard(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: "#CDEFE8", fill: "#FFFFFF", padding: 16) {
            HStack {
                HitRiseSectionTitle(title: "击打力度", subtitle: "实时力度曲线与峰值反馈", palette: palette)
                Text("峰值 \(Int(app.training.peakForceN)) N")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#096D65"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "#DFFFF7")))
            }
            ForceWaveformView(samples: app.training.forceSamples, palette: palette)
                .frame(height: 118)
            HStack(spacing: 8) {
                forceLegend("轻击", "#45DCC8")
                forceLegend("中击", "#9BE5C4")
                forceLegend("重拳", "#FFD060")
                forceLegend("爆发", "#FF7A45")
            }
            Text("最新 \(Int(app.training.latestForceN)) N · 峰值 \(Int(app.training.peakForceN)) N · 平均 \(Int(app.training.averageForceN)) N")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: palette.textSecondary))
        }
    }

    private func forceLegend(_ title: String, _ fill: String) -> some View {
        Text(title)
            .font(.caption2.weight(.black))
            .foregroundStyle(Color(hex: "#17343B"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color(hex: fill)))
    }

    private func homeConnectionReportCard(_ palette: HitRisePalette) -> some View {
        ZStack(alignment: .leading) {
            Color(hex: "#F3FFFC")
            Image("home_report_bg")
                .resizable()
                .scaledToFill()
                .frame(width: 150)
                .frame(maxHeight: .infinity)
                .clipped()
                .saturation(1.12)
                .contrast(1.03)
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .leading, spacing: 10) {
                Text("连接状态 / 最新战报")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(hex: "#17343B"))
                Text(connectionStatusText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#557A7D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.trailing, 48)
                HStack(spacing: 8) {
                    homeMiniMetric("本次拳数", value: reportHitsText)
                    homeMiniMetric("最大力度", value: reportPeakText)
                    homeMiniMetric("平均力度", value: reportAverageText)
                }
                .padding(.trailing, 28)
            }
            .padding(16)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(hex: "#CDEFE8"), lineWidth: 1))
    }

    private func homeGoalAchievementCard(_ palette: HitRisePalette) -> some View {
        ZStack(alignment: .leading) {
            Color(hex: "#F3FFFC")
            Image("home_achievement_bg")
                .resizable()
                .scaledToFill()
                .frame(width: 200)
                .frame(maxHeight: .infinity)
                .clipped()
                .saturation(1.12)
                .contrast(1.03)
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .leading, spacing: 12) {
                Text("目标与成就")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(hex: "#17343B"))
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日已完成")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#7FA0A3"))
                    Text("\(goalPercent)%")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#10BDAA"))
                }
                .frame(width: 140, height: 86, alignment: .leading)
                .padding(.horizontal, 14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#BDEFE6"), lineWidth: 1)))
                Text(nextBadgeText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#096D65"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color(hex: "#DFFFF7")))
                    .frame(maxWidth: 188, alignment: .leading)
            }
            .padding(16)
        }
        .frame(height: 172)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color(hex: "#CDEFE8"), lineWidth: 1))
    }

    private func homeMiniMetric(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "#7FA0A3"))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "#17343B"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E0F3EF"), lineWidth: 1)))
    }

    private func aiCoachCard(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: palette.isLight ? "#CDEFE8" : "#2E75B6", fill: palette.isLight ? "#FFFFFF" : "#0B1B27") {
            HStack {
                HitRiseBadge(text: app.training.coachStatus, palette: palette, fill: palette.isLight ? "#DFFFF7" : "#17354A", textColor: palette.isLight ? "#096D65" : palette.textPrimary)
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(Color(hex: palette.accent).opacity(0.35 + Double(index) * 0.12))
                            .frame(width: 5, height: CGFloat(12 + index * 4))
                    }
                }
            }
            Text(app.training.coachMessage)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color(hex: palette.textPrimary))
            Text(app.training.coachMeta)
                .font(.caption)
                .foregroundStyle(Color(hex: palette.textMuted))
        }
    }

    @ViewBuilder
    private func latestReportCard(_ palette: HitRisePalette) -> some View {
        HitRiseSectionTitle(title: "回合训练战报", subtitle: nil, palette: palette)
        if let report = app.training.latestReport {
            HitRiseCard(palette: palette, stroke: "#CDEFE8", fill: "#FFFFFF", padding: 16) {
                HStack {
                    HitRiseBadge(
                        text: "第 \(max(report.completedRounds, 1))/\(max(report.totalRounds, 1)) 回合",
                        palette: palette,
                        fill: "#E4FFF9",
                        textColor: "#0A9D90"
                    )
                    Spacer()
                    HitRiseBadge(text: "\(report.totalHits) 次", palette: palette, fill: "#FF9B42", textColor: "#FFFFFF")
                }

                VStack(spacing: 6) {
                    Text("第 \(max(report.completedRounds, 1)) 回合训练战报")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(hex: "#17343B"))
                    Text("累计锻炼 \(durationText(report.durationSeconds)) | 累计 \(report.totalHits) 拳 | \(String(format: "%.1f", report.caloriesBurned)) kcal | 等效燃脂 \(String(format: "%.1f", report.fatBurnedGrams)) g")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#557A7D"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    reportMetric("累计锻炼时间", durationText(report.durationSeconds), "#22C8BA")
                    reportMetric("累计击拳数", "\(report.totalHits) 次", "#22C8BA")
                    reportMetric("最大力度", forceText(report.peakForceN), "#E85E58")
                    reportMetric("平均力度", forceText(report.avgForceN), "#22C8BA")
                    reportMetric("消耗卡路里", "\(String(format: "%.1f", report.caloriesBurned)) kcal", "#78D98D")
                    reportMetric("等效燃脂", "\(String(format: "%.1f", report.fatBurnedGrams)) g", "#E5C859")
                    reportMetric("平均 BPM", "\(Int(report.avgBpm.rounded()))", "#56BFEA")
                    reportMetric("最佳连击", "\(report.bestBurstCount) 次", "#E5C859")
                }

                if !report.roundReports.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("回合累计战报")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color(hex: "#17343B"))
                        ForEach(report.roundReports.prefix(4)) { round in
                            Text("第 \(round.roundIndex) 回合：累计 \(durationText(round.durationSeconds)) | \(round.totalHits) 拳 | \(String(format: "%.1f", round.caloriesBurned)) kcal | 等效燃脂 \(String(format: "%.1f", round.fatBurnedGrams)) g")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color(hex: "#557A7D"))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#F5FFFC")))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#D6F2EC"), lineWidth: 1))
                }

                Text("训练已记录，今天的节奏又往前推进了一步。连续训练 \(app.trainingStreak) 天，XP +10。")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "#855F12"))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#FFF8E4")))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#F4D48A"), lineWidth: 1))

                ShareLink(item: shareText(report)) {
                    Text("分享战报")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color(hex: "#22C8BA")))
                }
                .buttonStyle(.plain)
            }
        } else {
            HitRiseCard(palette: palette, stroke: "#CDEFE8", fill: "#FFFFFF") {
                Text("暂无训练报告。连接设备后开始一组训练。")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: palette.textMuted))
            }
        }
    }

    private func reportMetric(_ title: String, _ value: String, _ stroke: String) -> some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color(hex: "#557A7D"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color(hex: stroke).opacity(0.78), lineWidth: 1.2))
    }
    private var statusLine: String {
        if let device = app.ble.connectedDevice {
            return "已连接 \(device.name) | \(app.ble.statusMessage)"
        }
        return "请先连接立式拳击速度球"
    }

    private var activeCompletedHits: Int {
        if app.training.totalHits > 0 || !app.training.canStart {
            return app.training.totalHits
        }
        return app.training.latestReport?.totalHits ?? 0
    }

    private var activeTargetHits: Int {
        switch app.training.selectedPlayMode {
        case .levelChallenge:
            return app.levelTargetHits()
        case .dailyChallenge:
            return app.dailyTargetHits()
        default:
            return 500
        }
    }

    private var bpmText: String {
        if app.training.totalHits > 0 {
            let plannedSeconds = max(1, app.training.selectedSetup.workMinutes * 60)
            let elapsedSeconds = max(1, plannedSeconds - app.training.remainingSeconds)
            let liveBpm = Int((Double(app.training.totalHits) / Double(elapsedSeconds) * 60).rounded())
            return "\(max(liveBpm, app.training.selectedSetup.bpm))"
        }
        if let report = app.training.latestReport, report.avgBpm > 0 {
            return "\(Int(report.avgBpm.rounded()))"
        }
        return "\(app.training.selectedSetup.bpm)"
    }

    private var caloriesText: String {
        String(format: "%.1f", activeCalories)
    }

    private var fatText: String {
        String(format: "%.1f", activeCalories / 7.7)
    }

    private var activeCalories: Double {
        if app.training.totalHits > 0 || !app.training.canStart {
            let forceFactor = max(0.7, min(1.5, max(app.training.averageForceN, 260) / 420))
            return Double(max(app.training.totalHits, 0)) * 0.063 * forceFactor
        }
        return app.training.latestReport?.caloriesBurned ?? 0
    }

    private func comboValue(_ key: String) -> Int {
        app.training.comboSummary[key] ?? app.training.latestReport?.comboSummary[key] ?? 0
    }

    private var phaseCaption: String {
        switch app.training.phase {
        case .resting(_, let seconds):
            return "休息 \(seconds)s"
        default:
            return app.training.phase.title
        }
    }

    private var timeText: String {
        let seconds = max(0, app.training.remainingSeconds)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var heroBadgeText: String {
        switch app.training.selectedPlayMode {
        case .levelChallenge:
            return "LEVEL \(app.trainingLevel)"
        case .dailyChallenge:
            return app.dailyTargetDone ? "今日已完成" : "每日挑战"
        default:
            return app.training.selectedPlayMode.title
        }
    }

    private var heroTitle: String {
        switch app.training.selectedPlayMode {
        case .levelChallenge:
            return "目标 \(app.levelTargetHits()) 拳，升级到下一关"
        case .dailyChallenge:
            return "今日目标 \(app.dailyTargetHits()) 拳"
        default:
            return "立式拳击速度球训练"
        }
    }

    private var heroSummary: String {
        "回合 \(app.training.selectedSetup.label) | \(app.training.selectedSetup.rhythmMode.title)模式 | \(app.training.selectedSetup.bpm) BPM"
    }

    private var heroProgress: String {
        "等级 \(app.trainingLevel) | XP \(app.trainingXP) | 连续 \(app.trainingStreak) 天"
    }

    private func shareText(_ report: TrainingReport) -> String {
        "我刚完成智能拳击速度球训练战报：累计锻炼 \(durationText(report.durationSeconds))，累计击打 \(report.totalHits) 次，最大力度 \(forceText(report.peakForceN))，平均力度 \(forceText(report.avgForceN))，消耗 \(String(format: "%.1f", report.caloriesBurned)) kcal，等效燃脂约 \(String(format: "%.1f", report.fatBurnedGrams)) g。"
    }

    private var connectionStatusText: String {
        if let device = app.ble.connectedDevice {
            return "\(device.name)·电量 \(app.ble.latestTelemetry?.batteryText ?? "--")·已连接"
        }
        return "没有连接蓝牙设备"
    }

    private var reportHitsText: String {
        if !app.training.canStart || app.training.totalHits > 0 {
            return "\(app.training.totalHits)"
        }
        return "\(app.training.latestReport?.totalHits ?? 0)"
    }

    private var reportPeakText: String {
        let value = max(app.training.peakForceN, app.training.latestReport?.peakForceN ?? 0)
        return value > 0 ? forceText(value) : "--"
    }

    private var reportAverageText: String {
        let value = max(app.training.averageForceN, app.training.latestReport?.avgForceN ?? 0)
        return value > 0 ? forceText(value) : "--"
    }

    private var goalPercent: Int {
        let target: Int
        switch app.training.selectedPlayMode {
        case .levelChallenge:
            target = app.levelTargetHits()
        case .dailyChallenge:
            target = app.dailyTargetHits()
        default:
            target = 500
        }
        let completed = app.training.totalHits > 0 ? app.training.totalHits : (app.training.latestReport?.totalHits ?? 0)
        guard target > 0 else { return 0 }
        return min(999, max(0, Int((Double(completed) / Double(target) * 100).rounded())))
    }

    private var nextBadgeText: String {
        if let next = app.achievements.filter({ !$0.unlocked }).sorted(by: { $0.sortOrder < $1.sortOrder }).first {
            return "下一枚徽章：\(achievementName(next.key))"
        }
        return "全部徽章已解锁"
    }

    private func achievementName(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func forceText(_ value: Double) -> String {
        "\(Int(value)) N"
    }

    private func durationText(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60)分\(seconds % 60)秒"
        }
        return "\(seconds)秒"
    }
}

struct HomeImageActionButton: View {
    let title: String
    let assetName: String
    let palette: HitRisePalette
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}

struct HomeMetricTile: View {
    let iconName: String
    let title: String
    let value: String
    let unit: String
    let palette: HitRisePalette
    var accent: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Color(hex: palette.textMuted))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: accent ?? palette.textPrimary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(hex: palette.textMuted))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hex: "#E0F3EF"), lineWidth: 1))
                .shadow(color: Color(hex: "#8FE5D8").opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }
}

struct MiniProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "#D7F7F1"))
                Capsule()
                    .fill(Color(hex: "#22C8BA"))
                    .frame(width: max(8, width * min(1, max(0, progress))))
            }
        }
    }
}

struct CircularTimerRing: View {
    let progress: Double
    let center: String
    let caption: String
    let palette: HitRisePalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#DDF8F3"), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(Color(hex: "#23C8BA"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color(hex: "#F05A4F"))
                .frame(width: 10, height: 10)
                .offset(y: -48)
            VStack(spacing: 4) {
                Text(center)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#E85E58"))
                Text(caption)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(hex: "#8AA3A4"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct ForceWaveformView: View {
    let samples: [Double]
    let palette: HitRisePalette

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(samples.max() ?? 120, 120)
            HStack(alignment: .bottom, spacing: 3) {
                if samples.isEmpty {
                    Text("等待击打力度")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: palette.textSecondary))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ForEach(Array(samples.enumerated()), id: \.offset) { _, value in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(forceColor(value))
                            .frame(height: max(8, proxy.size.height * CGFloat(value / maxValue)))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: palette.cardAlt))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: palette.stroke), lineWidth: 1))
            )
        }
    }

    private func forceColor(_ value: Double) -> Color {
        if value > 160 { return Color(hex: palette.forceHigh) }
        if value > 80 { return Color(hex: palette.forceMid) }
        return Color(hex: palette.forceLow)
    }
}

struct TrainingSetupView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var setup = TrainingSessionSetup()

    var body: some View {
        let palette = app.palette
        NavigationStack {
            ZStack {
                Color(hex: palette.backgroundBottom).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        HitRiseCard(palette: palette) {
                            stepperRow("训练分钟", value: $setup.workMinutes, range: 1...10, suffix: "min")
                            stepperRow("休息间隔", value: $setup.restHalfMinutes, range: 0...10, suffix: "x30s")
                            stepperRow("回合数", value: $setup.rounds, range: 1...10, suffix: "rounds")
                            Picker("节奏模式", selection: $setup.rhythmMode) {
                                ForEach(TrainingRhythmMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            stepperRow("BPM", value: $setup.bpm, range: 40...140, suffix: "bpm")
                        }
                        HitRiseActionButton(title: "保存训练设置", systemImage: "checkmark", palette: palette, fill: palette.accentHot) {
                            app.updateTrainingSetup(setup)
                            dismiss()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("训练设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .onAppear { setup = app.training.selectedSetup }
        .preferredColorScheme(palette.isLight ? .light : .dark)
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text("\(value.wrappedValue) \(suffix)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Stepper(title, value: value, in: range)
                .labelsHidden()
        }
    }
}
