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
                    Text(app.localized("实时训练", "Live Training", "Entraînement en direct", "ฝึกสด"))
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(hex: "#17343B"))
                    Spacer(minLength: 8)
                    HitRiseBadge(
                        text: roundBadgeText(current: app.training.currentRound, total: app.training.totalRounds),
                        palette: palette,
                        fill: "#E4FFF9",
                        textColor: "#0A9D90"
                    )
                    Button {
                        showingTrainingSettings = true
                    } label: {
                        Label(trainingSettingsTitle, systemImage: "gearshape")
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
                Text(app.localized("家庭健身 · 燃脂拳击", "Home Fitness · Fat-Burning Boxing", "Fitness à domicile · Boxe brûle-graisse", "ฟิตเนสที่บ้าน · ชกมวยเผาผลาญไขมัน"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#4C7478"))
                    .padding(.top, 6)
                Text(app.localized("10分钟\n轻松暴汗！", "10 minutes\nto a great sweat!", "10 minutes\npour bien transpirer !", "10 นาที\nเหงื่อท่วมสบายๆ!"))
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
                Text(app.localized("健身 | 减压 | 燃脂", "Fitness | Stress Relief | Fat Burn", "Forme | Anti-stress | Brûle-graisse", "ฟิตเนส | คลายเครียด | เผาผลาญไขมัน"))
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
                title: app.localized("开始", "Start", "Démarrer", "เริ่ม"),
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
                    caption: app.localized("回合时间", "Round time", "Temps du round", "เวลารอบ"),
                    palette: palette
                )
                .padding(9)
            }
            .frame(width: 126, height: 126)

            roundActionButton(
                title: app.localized("结束", "Stop", "Arrêter", "หยุด"),
                fill: "#F6B986",
                disabled: app.training.canStart
            ) {
                app.stopTraining()
            }
        }
    }

    private func realtimeDashboard(_ palette: HitRisePalette) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            HomeMetricTile(iconName: "home_metric_hits", title: app.localized("拳数", "Punches", "Coups", "หมัด"), value: reportHitsText, unit: hitUnit, palette: palette, accent: "#17343B")
            HomeMetricTile(iconName: "home_metric_bpm", title: "BPM", value: bpmText, unit: "", palette: palette, accent: "#17343B")
            HomeMetricTile(iconName: "home_metric_calories", title: app.localized("卡路里", "Calories", "Calories", "แคลอรี"), value: caloriesText, unit: "kcal", palette: palette, accent: "#17343B")
            HomeMetricTile(iconName: "home_metric_fat", title: app.localized("等效燃脂", "Fat Burn", "Graisse brûlée", "ไขมันที่เผาผลาญ"), value: fatText, unit: "g", palette: palette, accent: "#17343B")
        }
    }

    private func trainingProgressRow(_ palette: HitRisePalette) -> some View {
        HStack(spacing: 8) {
            Text(app.localized("今日目标:", "Today's goal:", "Objectif du jour :", "เป้าวันนี้:"))
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "#557A7D"))
            Text(punchCountText(activeTargetHits))
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
            Text("| \(app.localized("已完成", "Done", "Fait", "ทำแล้ว")) \(punchCountText(activeCompletedHits))")
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
            MiniProgressBar(progress: min(1, Double(activeCompletedHits) / Double(max(activeTargetHits, 1))))
                .frame(width: 104, height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comboRecognitionRow(_ palette: HitRisePalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(app.localized("连击识别", "Combo Recognition", "Reconnaissance des combos", "การจดจำคอมโบ"))
                .font(.caption.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    comboPill(app.localized("重击", "Heavy", "Puissant", "หนัก"), "\(comboValue("heavy_hit"))", fill: "#F5FFFC", stroke: "#CDEFE8", text: "#557A7D")
                    comboPill(app.localized("速击", "Fast", "Rapide", "เร็ว"), "\(comboValue("fast_combo"))", fill: "#DFFFF7", stroke: "#BCEFE6", text: "#0B9F91")
                    comboPill(app.localized("三连击", "Triple", "Triple", "สามต่อ"), nil, fill: "#F5FFFC", stroke: "#CDEFE8", text: "#557A7D")
                    comboPill(app.localized("爆发连击", "Burst", "Rafale", "ระเบิด"), "\(app.training.latestReport?.bestBurstCount ?? app.training.comboSummary["sixteen_chain"] ?? 0)", fill: "#FF784B", stroke: "#FF784B", text: "#FFFFFF")
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
                HitRiseSectionTitle(
                    title: app.localized("相对力量评分", "Relative Power Score", "Score de puissance relative", "คะแนนพลังสัมพัทธ์"),
                    subtitle: app.localized("实时评分曲线与峰值反馈", "Live score curve and peak feedback", "Courbe du score et pic en direct", "กราฟคะแนนสดและค่าสูงสุด"),
                    palette: palette
                )
                Text("\(app.localized("峰值评分", "Peak score", "Score max.", "คะแนนสูงสุด")) \(Int(app.training.peakForceN))")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#096D65"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "#DFFFF7")))
            }
            ForceWaveformView(
                samples: app.training.forceSamples,
                palette: palette,
                emptyLabel: app.localized("等待相对力量评分", "Waiting for Relative Power Score", "En attente du score de puissance relative", "รอคะแนนพลังสัมพัทธ์")
            )
                .frame(height: 118)
            HStack(spacing: 8) {
                forceLegend(app.localized("轻击", "Light", "Léger", "เบา"), "#45DCC8")
                forceLegend(app.localized("中击", "Medium", "Moyen", "กลาง"), "#9BE5C4")
                forceLegend(app.localized("重拳", "Heavy", "Fort", "หนัก"), "#FFD060")
                forceLegend(app.localized("爆发", "Burst", "Explosif", "ระเบิด"), "#FF7A45")
            }
            Text("\(app.localized("最新", "Latest", "Dernier", "ล่าสุด")) \(Int(app.training.latestForceN)) · \(app.localized("峰值", "Peak", "Pic", "สูงสุด")) \(Int(app.training.peakForceN)) · \(app.localized("平均", "Average", "Moyenne", "เฉลี่ย")) \(Int(app.training.averageForceN))")
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
                Text(app.localized("连接状态 / 最新战报", "Connection / Latest Report", "Connexion / Dernier rapport", "การเชื่อมต่อ / รายงานล่าสุด"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(hex: "#17343B"))
                Text(connectionStatusText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color(hex: "#557A7D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.trailing, 48)
                HStack(spacing: 8) {
                    homeMiniMetric(app.localized("本次拳数", "Punches", "Coups", "หมัดครั้งนี้"), value: reportHitsText)
                    homeMiniMetric(app.localized("峰值评分", "Peak score", "Score max.", "คะแนนสูงสุด"), value: reportPeakText)
                    homeMiniMetric(app.localized("平均评分", "Average score", "Score moyen", "คะแนนเฉลี่ย"), value: reportAverageText)
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
                Text(app.localized("目标与成就", "Goals & Achievements", "Objectifs et succès", "เป้าหมายและความสำเร็จ"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color(hex: "#17343B"))
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.localized("今日已完成", "Done today", "Fait aujourd'hui", "วันนี้ทำแล้ว"))
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
        HitRiseSectionTitle(title: app.localized("回合训练战报", "Round Training Report", "Rapport des rounds", "รายงานการฝึกรายรอบ"), subtitle: nil, palette: palette)
        if let report = app.training.latestReport {
            HitRiseCard(palette: palette, stroke: "#CDEFE8", fill: "#FFFFFF", padding: 16) {
                HStack {
                    HitRiseBadge(
                        text: roundBadgeText(current: max(report.completedRounds, 1), total: max(report.totalRounds, 1)),
                        palette: palette,
                        fill: "#E4FFF9",
                        textColor: "#0A9D90"
                    )
                    Spacer()
                    HitRiseBadge(text: hitCountText(report.totalHits), palette: palette, fill: "#FF9B42", textColor: "#FFFFFF")
                }

                VStack(spacing: 6) {
                    Text(reportTitleText(round: max(report.completedRounds, 1)))
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(hex: "#17343B"))
                    Text(reportSummaryText(
                        durationSeconds: report.durationSeconds,
                        hits: report.totalHits,
                        calories: report.caloriesBurned,
                        fatGrams: report.fatBurnedGrams
                    ))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "#557A7D"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    reportMetric(app.localized("累计锻炼时间", "Training Time", "Temps d'entraînement", "เวลาฝึกรวม"), durationText(report.durationSeconds), "#22C8BA")
                    reportMetric(app.localized("累计击拳数", "Total Punches", "Total de coups", "หมัดรวม"), hitCountText(report.totalHits), "#22C8BA")
                    reportMetric(app.localized("相对力量峰值评分", "Peak Relative Power Score", "Score relatif max.", "คะแนนพลังสัมพัทธ์สูงสุด"), forceText(report.peakForceN), "#E85E58")
                    reportMetric(app.localized("平均相对力量评分", "Average Relative Power Score", "Score relatif moyen", "คะแนนพลังสัมพัทธ์เฉลี่ย"), forceText(report.avgForceN), "#22C8BA")
                    reportMetric(app.localized("消耗卡路里", "Calories Burned", "Calories brûlées", "แคลอรีที่เผาผลาญ"), "\(String(format: "%.1f", report.caloriesBurned)) kcal", "#78D98D")
                    reportMetric(app.localized("等效燃脂", "Fat Burn", "Graisse brûlée", "ไขมันที่เผาผลาญ"), "\(String(format: "%.1f", report.fatBurnedGrams)) g", "#E5C859")
                    reportMetric(app.localized("平均 BPM", "Average BPM", "BPM moyen", "BPM เฉลี่ย"), "\(Int(report.avgBpm.rounded()))", "#56BFEA")
                    reportMetric(app.localized("最佳连击", "Best Combo", "Meilleur combo", "คอมโบดีที่สุด"), hitCountText(report.bestBurstCount), "#E5C859")
                }

                if !report.roundReports.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.localized("回合累计战报", "Round Breakdown", "Détail par round", "สรุปรายรอบ"))
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color(hex: "#17343B"))
                        ForEach(report.roundReports.prefix(4)) { round in
                            Text(roundLineText(round))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color(hex: "#557A7D"))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#F5FFFC")))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#D6F2EC"), lineWidth: 1))
                }

                Text(app.localized(
                    "训练已记录，今天的节奏又往前推进了一步。连续训练 \(app.trainingStreak) 天，XP +10。",
                    "Training saved. You pushed your rhythm forward today. \(app.trainingStreak)-day streak, XP +10.",
                    "Entraînement enregistré. Votre rythme progresse aujourd'hui. Série de \(app.trainingStreak) j, XP +10.",
                    "บันทึกการฝึกแล้ว วันนี้จังหวะของคุณก้าวหน้าขึ้นอีกขั้น ฝึกต่อเนื่อง \(app.trainingStreak) วัน XP +10"
                ))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "#855F12"))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "#FFF8E4")))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#F4D48A"), lineWidth: 1))

                ShareLink(item: shareText(report)) {
                    Text(app.localized("分享战报", "Share Report", "Partager le rapport", "แชร์รายงาน"))
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
                Text(app.localized("暂无训练报告。连接设备后开始一组训练。", "No training report yet. Connect your device and start a session.", "Aucun rapport pour l'instant. Connectez l'appareil et lancez une séance.", "ยังไม่มีรายงานการฝึก เชื่อมต่ออุปกรณ์แล้วเริ่มฝึกได้เลย"))
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
            return "\(app.localized("已连接", "Connected", "Connecté", "เชื่อมต่อแล้ว")) \(device.name) | \(app.ble.statusMessage)"
        }
        return app.localized("请先连接立式拳击速度球", "Please connect the boxing speed ball first", "Connectez d'abord le punching-ball", "โปรดเชื่อมต่อลูกบอลชกมวยก่อน")
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
            let powerFactor = max(0.7, min(1.5, max(app.training.averageForceN, 433.333) / 700))
            return Double(max(app.training.totalHits, 0)) * 0.063 * powerFactor
        }
        return app.training.latestReport?.caloriesBurned ?? 0
    }

    private func comboValue(_ key: String) -> Int {
        app.training.comboSummary[key] ?? app.training.latestReport?.comboSummary[key] ?? 0
    }

    private var phaseCaption: String {
        switch app.training.phase {
        case .resting(_, let seconds):
            return app.localized("休息 \(seconds)s", "Rest \(seconds)s", "Repos \(seconds)s", "พัก \(seconds) วิ")
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
            return app.dailyTargetDone
                ? app.localized("今日已完成", "Done today", "Fait aujourd'hui", "วันนี้ทำแล้ว")
                : app.localized("每日挑战", "Daily Challenge", "Défi du jour", "ท้าทายประจำวัน")
        default:
            return app.training.selectedPlayMode.title
        }
    }

    private var heroTitle: String {
        switch app.training.selectedPlayMode {
        case .levelChallenge:
            let target = app.levelTargetHits()
            return app.localized("目标 \(target) 拳，升级到下一关", "Hit \(target) punches to reach the next level", "\(target) coups pour passer au niveau suivant", "ออกหมัด \(target) ครั้งเพื่อผ่านด่านถัดไป")
        case .dailyChallenge:
            let target = app.dailyTargetHits()
            return app.localized("今日目标 \(target) 拳", "Today's goal: \(target) punches", "Objectif du jour : \(target) coups", "เป้าวันนี้ \(target) หมัด")
        default:
            return app.localized("立式拳击速度球训练", "Boxing Speed Ball Training", "Entraînement au punching-ball", "ฝึกลูกบอลชกมวย")
        }
    }

    private var heroSummary: String {
        let setup = app.training.selectedSetup
        return app.localized(
            "回合 \(setup.label) | \(setup.rhythmMode.title)模式 | \(setup.bpm) BPM",
            "Rounds \(setup.label) | \(setup.rhythmMode.title) mode | \(setup.bpm) BPM",
            "Rounds \(setup.label) | Mode \(setup.rhythmMode.title) | \(setup.bpm) BPM",
            "รอบ \(setup.label) | โหมด\(setup.rhythmMode.title) | \(setup.bpm) BPM"
        )
    }

    private var heroProgress: String {
        app.localized(
            "等级 \(app.trainingLevel) | XP \(app.trainingXP) | 连续 \(app.trainingStreak) 天",
            "Level \(app.trainingLevel) | XP \(app.trainingXP) | \(app.trainingStreak)-day streak",
            "Niveau \(app.trainingLevel) | XP \(app.trainingXP) | Série de \(app.trainingStreak) j",
            "ระดับ \(app.trainingLevel) | XP \(app.trainingXP) | ต่อเนื่อง \(app.trainingStreak) วัน"
        )
    }

    private func shareText(_ report: TrainingReport) -> String {
        app.localized(
            "我刚完成智能拳击速度球训练战报：累计锻炼 \(durationText(report.durationSeconds))，累计击打 \(report.totalHits) 次，相对力量峰值评分 \(forceText(report.peakForceN))，平均评分 \(forceText(report.avgForceN))，消耗 \(String(format: "%.1f", report.caloriesBurned)) kcal，等效燃脂约 \(String(format: "%.1f", report.fatBurnedGrams)) g。",
            "I completed a smart boxing ball session: \(durationText(report.durationSeconds)), \(report.totalHits) punches, peak Relative Power Score \(forceText(report.peakForceN)), average score \(forceText(report.avgForceN)), \(String(format: "%.1f", report.caloriesBurned)) kcal, and about \(String(format: "%.1f", report.fatBurnedGrams)) g equivalent fat burn.",
            "J'ai terminé une séance : \(durationText(report.durationSeconds)), \(report.totalHits) coups, score de puissance relative max. \(forceText(report.peakForceN)), score moyen \(forceText(report.avgForceN)), \(String(format: "%.1f", report.caloriesBurned)) kcal et environ \(String(format: "%.1f", report.fatBurnedGrams)) g de graisse équivalente.",
            "ฉันฝึกชกมวยอัจฉริยะเสร็จแล้ว: \(durationText(report.durationSeconds)), \(report.totalHits) หมัด, คะแนนพลังสัมพัทธ์สูงสุด \(forceText(report.peakForceN)), คะแนนเฉลี่ย \(forceText(report.avgForceN)), \(String(format: "%.1f", report.caloriesBurned)) kcal และไขมันเทียบเท่าประมาณ \(String(format: "%.1f", report.fatBurnedGrams)) g"
        )
    }

    private var connectionStatusText: String {
        if let device = app.ble.connectedDevice {
            let battery = app.ble.latestTelemetry?.batteryText ?? "--"
            return app.localized(
                "\(device.name)·电量 \(battery)·已连接",
                "\(device.name) · Battery \(battery) · Connected",
                "\(device.name) · Batterie \(battery) · Connecté",
                "\(device.name) · แบตเตอรี่ \(battery) · เชื่อมต่อแล้ว"
            )
        }
        return app.localized("没有连接蓝牙设备", "No Bluetooth device connected", "Aucun appareil Bluetooth connecté", "ไม่ได้เชื่อมต่ออุปกรณ์บลูทูธ")
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
            let name = achievementName(next.key)
            return app.localized("下一枚徽章：\(name)", "Next badge: \(name)", "Prochain badge : \(name)", "เหรียญถัดไป: \(name)")
        }
        return app.localized("全部徽章已解锁", "All badges unlocked", "Tous les badges débloqués", "ปลดล็อกเหรียญครบแล้ว")
    }

    private func achievementName(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func forceText(_ value: Double) -> String {
        "\(Int(value))"
    }

    private func durationText(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if seconds >= 60 {
            return app.localized("\(minutes)分\(remainder)秒", "\(minutes)m \(remainder)s", "\(minutes) min \(remainder) s", "\(minutes) นาที \(remainder) วิ")
        }
        return app.localized("\(seconds)秒", "\(seconds)s", "\(seconds) s", "\(seconds) วิ")
    }

    private var trainingSettingsTitle: String {
        app.localized("训练设置", "Training Settings", "Réglages", "ตั้งค่าการฝึก")
    }

    private var hitUnit: String {
        app.localized("次", "hits", "coups", "ครั้ง")
    }

    private func hitCountText(_ count: Int) -> String {
        app.localized("\(count) 次", "\(count) hits", "\(count) coups", "\(count) ครั้ง")
    }

    private func punchCountText(_ count: Int) -> String {
        app.localized("\(count) 拳", "\(count) punches", "\(count) coups", "\(count) หมัด")
    }

    private func roundBadgeText(current: Int, total: Int) -> String {
        app.localized("第 \(current) / \(total) 回合", "Round \(current) / \(total)", "Round \(current) / \(total)", "รอบ \(current) / \(total)")
    }

    private func reportTitleText(round: Int) -> String {
        app.localized("第 \(round) 回合训练战报", "Round \(round) Training Report", "Rapport du round \(round)", "รายงานการฝึกรอบที่ \(round)")
    }

    private func reportSummaryText(durationSeconds: Int, hits: Int, calories: Double, fatGrams: Double) -> String {
        let duration = durationText(durationSeconds)
        let kcal = String(format: "%.1f", calories)
        let fat = String(format: "%.1f", fatGrams)
        return app.localized(
            "累计锻炼 \(duration) | 累计 \(hits) 拳 | \(kcal) kcal | 等效燃脂 \(fat) g",
            "Time \(duration) | \(hits) punches | \(kcal) kcal | Fat burn \(fat) g",
            "Durée \(duration) | \(hits) coups | \(kcal) kcal | Graisse \(fat) g",
            "เวลา \(duration) | \(hits) หมัด | \(kcal) kcal | ไขมัน \(fat) g"
        )
    }

    private func roundLineText(_ round: TrainingRoundReport) -> String {
        let duration = durationText(round.durationSeconds)
        let kcal = String(format: "%.1f", round.caloriesBurned)
        let fat = String(format: "%.1f", round.fatBurnedGrams)
        let index = round.roundIndex
        let hits = round.totalHits
        return app.localized(
            "第 \(index) 回合：累计 \(duration) | \(hits) 拳 | \(kcal) kcal | 等效燃脂 \(fat) g",
            "Round \(index): \(duration) | \(hits) punches | \(kcal) kcal | Fat burn \(fat) g",
            "Round \(index) : \(duration) | \(hits) coups | \(kcal) kcal | Graisse \(fat) g",
            "รอบที่ \(index): \(duration) | \(hits) หมัด | \(kcal) kcal | ไขมัน \(fat) g"
        )
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
    let emptyLabel: String

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(samples.max() ?? 200, 200)
            HStack(alignment: .bottom, spacing: 3) {
                if samples.isEmpty {
                    Text(emptyLabel)
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
        if value > 266.667 { return Color(hex: palette.forceHigh) }
        if value > 133.333 { return Color(hex: palette.forceMid) }
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
                            stepperRow(app.localized("训练分钟", "Work minutes", "Minutes d'effort", "นาทีที่ฝึก"), value: $setup.workMinutes, range: 1...10, suffix: "min")
                            stepperRow(app.localized("休息间隔", "Rest interval", "Repos", "ช่วงพัก"), value: $setup.restHalfMinutes, range: 0...10, suffix: "x30s")
                            stepperRow(app.localized("回合数", "Rounds", "Rounds", "จำนวนรอบ"), value: $setup.rounds, range: 1...10, suffix: "rounds")
                            Picker(app.localized("节奏模式", "Rhythm mode", "Mode rythme", "โหมดจังหวะ"), selection: $setup.rhythmMode) {
                                ForEach(TrainingRhythmMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            stepperRow("BPM", value: $setup.bpm, range: 100...300, suffix: "bpm")
                        }
                        HitRiseActionButton(title: app.localized("保存训练设置", "Save Training Settings", "Enregistrer les réglages", "บันทึกการตั้งค่าการฝึก"), systemImage: "checkmark", palette: palette, fill: palette.accentHot) {
                            app.updateTrainingSetup(setup)
                            dismiss()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(app.localized("训练设置", "Training Settings", "Réglages", "ตั้งค่าการฝึก"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(app.localized("关闭", "Close", "Fermer", "ปิด")) { dismiss() }
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
