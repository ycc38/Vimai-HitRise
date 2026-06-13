import SwiftUI

struct TrainingDashboardView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    modePicker
                    realtimeStats
                    actionButtons
                    latestReport
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Vimai HitRise")
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Text(app.training.phase.title)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.55)
            Text(statusLine)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("\(app.training.remainingSeconds)s")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
    }

    private var modePicker: some View {
        Picker("训练模式", selection: Binding(
            get: { app.training.selectedMode },
            set: { app.training.selectMode($0) }
        )) {
            ForEach(TrainingMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .disabled(!app.training.canStart)
    }

    private var realtimeStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "拳数", value: "\(app.training.totalHits)", unit: "hits", tint: .orange)
            StatTile(title: "最新力度", value: "\(Int(app.training.latestForceN))", unit: "N", tint: .red)
            StatTile(title: "峰值力度", value: "\(Int(app.training.peakForceN))", unit: "N", tint: .purple)
            StatTile(title: "平均力度", value: "\(Int(app.training.averageForceN))", unit: "N", tint: .blue)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                app.startTraining()
            } label: {
                Label("开始训练", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!app.training.canStart)

            Button(role: .destructive) {
                app.stopTraining()
            } label: {
                Label("停止并保存", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private var latestReport: some View {
        if let report = app.training.latestReport {
            VStack(alignment: .leading, spacing: 12) {
                Text("最新报告")
                    .font(.headline)
                HStack {
                    Label("\(report.totalHits) 拳", systemImage: "bolt.fill")
                    Spacer()
                    Label(String(format: "%.1f kcal", report.caloriesBurned), systemImage: "flame.fill")
                }
                .foregroundStyle(.secondary)
                HStack {
                    Text("频率 \(String(format: "%.2f", report.averageFrequency))/s")
                    Spacer()
                    Text("爆发 \(report.bestBurstCount) 拳")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(.background))
        }
    }

    private var statusLine: String {
        if let device = app.ble.connectedDevice {
            return "已连接 \(device.name) | \(app.ble.statusMessage)"
        }
        return "请先连接立式拳击速度球"
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let unit: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(tint.opacity(0.12)))
    }
}
