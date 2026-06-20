import Foundation
import SwiftUI

struct TrainingDashboardView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var showingTrainingSettings = false

    var body: some View {
        let palette = app.palette
        ScrollView {
            VStack(spacing: 14) {
                trainingControlPanel(palette)
                trainingHero(palette)
                aiCoachCard(palette)
                latestReportCard(palette)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingTrainingSettings) {
            TrainingSetupView()
                .environmentObject(app)
        }
    }

    private func trainingControlPanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: palette.strokeStrong, fill: palette.card, padding: 12) {
            VStack(spacing: 14) {
                HStack {
                    HitRiseSectionTitle(title: "训练中心", subtitle: statusLine, palette: palette)
                    Button {
                        showingTrainingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color(hex: palette.accentHot))
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color(hex: palette.cardAlt)))
                    }
                    .buttonStyle(.plain)
                }
                playModeGrid(palette)
                timerAndCount(palette)
                realtimeDashboard(palette)
                ForceWaveformView(samples: app.training.forceSamples, palette: palette)
                    .frame(height: 86)
                HStack(spacing: 12) {
                    HitRiseActionButton(
                        title: "开始训练",
                        systemImage: "play.fill",
                        palette: palette,
                        fill: palette.accentHot,
                        disabled: !app.training.canStart
                    ) {
                        app.startTraining()
                    }
                    HitRiseActionButton(
                        title: "停止保存",
                        systemImage: "stop.fill",
                        palette: palette,
                        fill: palette.danger,
                        disabled: app.training.canStart
                    ) {
                        app.stopTraining()
                    }
                }
            }
            .background {
                Image("training_center_watermark")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.16)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
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
                            .foregroundStyle(Color(hex: selected ? palette.buttonText : palette.textPrimary))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(mode.subtitle)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: selected ? palette.buttonText : palette.textMuted).opacity(selected ? 0.82 : 1))
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

    private func timerAndCount(_ palette: HitRisePalette) -> some View {
        HStack(spacing: 16) {
            CircularTimerRing(
                progress: app.training.progressFraction,
                center: timeText,
                caption: phaseCaption,
                palette: palette
            )
            .frame(width: 138, height: 138)

            VStack(alignment: .leading, spacing: 6) {
                HitRiseBadge(text: "第 \(app.training.currentRound)/\(app.training.totalRounds) 回合", palette: palette)
                Text("\(app.training.totalHits)")
                    .font(.system(size: 74, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: palette.textPrimary))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("累计击拳数")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: palette.textSecondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func realtimeDashboard(_ palette: HitRisePalette) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            HitRiseMetricTile(title: "最新力度", value: "\(Int(app.training.latestForceN))", unit: "N", palette: palette, accent: palette.forceMid)
            HitRiseMetricTile(title: "峰值力度", value: "\(Int(app.training.peakForceN))", unit: "N", palette: palette, accent: palette.forceHigh)
            HitRiseMetricTile(title: "平均力度", value: "\(Int(app.training.averageForceN))", unit: "N", palette: palette, accent: palette.forceLow)
            HitRiseMetricTile(title: "节奏准确", value: "\(Int(app.training.rhythmSummary.accuracy * 100))", unit: "%", palette: palette, accent: palette.accentHot)
        }
    }

    private func trainingHero(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: palette.accent, fill: "#061410") {
            HitRiseBadge(text: heroBadgeText, palette: palette)
            Text(heroTitle)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: palette.textSecondary))
                .minimumScaleFactor(0.75)
            Text(heroSummary)
                .font(.subheadline)
                .foregroundStyle(Color(hex: palette.textSecondary))
            Text(heroProgress)
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color(hex: palette.accentHot))
        }
    }

    private func aiCoachCard(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette, stroke: "#2E75B6", fill: "#0B1B27") {
            HStack {
                HitRiseBadge(text: app.training.coachStatus, palette: palette, fill: "#17354A", textColor: palette.textPrimary)
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
        HitRiseSectionTitle(title: "最新报告", subtitle: "训练结束后自动上传云端", palette: palette)
        if let report = app.training.latestReport {
            HitRiseCard(palette: palette) {
                HStack {
                    HitRiseBadge(text: "训练战报", palette: palette, fill: palette.accentHot)
                    Spacer()
                    ShareLink(item: shareText(report)) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color(hex: palette.accentHot))
                    }
                }
                HStack {
                    HitRiseMetricTile(title: "拳数", value: "\(report.totalHits)", unit: "hits", palette: palette, accent: palette.accentHot)
                    HitRiseMetricTile(title: "热量", value: String(format: "%.1f", report.caloriesBurned), unit: "kcal", palette: palette, accent: palette.warning)
                }
                HStack {
                    Text("峰值 \(Int(report.peakForceN)) N | 平均 \(Int(report.avgForceN)) N")
                    Spacer()
                    Text("频率 \(String(format: "%.2f", report.averageFrequency))/s")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: palette.textSecondary))
            }
        } else {
            HitRiseCard(palette: palette) {
                Text("暂无训练报告。连接设备后开始一组训练。")
                    .foregroundStyle(Color(hex: palette.textMuted))
            }
        }
    }

    private var statusLine: String {
        if let device = app.ble.connectedDevice {
            return "已连接 \(device.name) | \(app.ble.statusMessage)"
        }
        return "请先连接立式拳击速度球"
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
        "Vimai HitRise 训练战报：\(report.totalHits) 拳，峰值 \(Int(report.peakForceN)) N，消耗 \(String(format: "%.1f", report.caloriesBurned)) kcal。"
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
                .stroke(Color(hex: palette.cardAlt), lineWidth: 11)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(Color(hex: palette.accentHot), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(center)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: palette.accentHot))
                Text(caption)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(hex: palette.textSecondary))
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
        .preferredColorScheme(.dark)
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
