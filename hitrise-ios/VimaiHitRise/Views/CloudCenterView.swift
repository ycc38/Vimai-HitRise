import SwiftUI

struct CloudCenterView: View {
    @EnvironmentObject private var app: AppViewModel

    private let boards = [
        ("total_hits", "总拳数"),
        ("peak_force_n", "峰值力度"),
        ("avg_force_n", "平均力度"),
        ("calories_burned", "卡路里")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("云端状态") {
                    HStack {
                        if app.isCloudBusy {
                            ProgressView()
                        } else {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.blue)
                        }
                        Text(app.cloudMessage)
                    }
                    Button {
                        Task { await app.refreshCloudData() }
                    } label: {
                        Label("刷新云端数据", systemImage: "arrow.clockwise")
                    }
                }

                if let stats = app.statistics {
                    Section("我的统计") {
                        LabeledContent("总训练", value: "\(stats.totalSessions) 次")
                        LabeledContent("总拳数", value: "\(stats.totalHits)")
                        LabeledContent("最佳 30 秒", value: "\(stats.best30Hits)")
                        LabeledContent("最佳力度", value: "\(Int(stats.bestPeakForceN)) N")
                    }
                }

                Section("排行榜") {
                    Picker("榜单", selection: Binding(
                        get: { app.selectedLeaderboardBoard },
                        set: { app.changeLeaderboardBoard($0) }
                    )) {
                        ForEach(boards, id: \.0) { board in
                            Text(board.1).tag(board.0)
                        }
                    }
                    ForEach(app.leaderboard) { entry in
                        HStack {
                            Text("#\(entry.rank)")
                                .font(.headline)
                                .frame(width: 46, alignment: .leading)
                            VStack(alignment: .leading) {
                                Text(entry.nickname)
                                Text(entry.serialMasked)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(entry.scoreValue))")
                                .font(.headline)
                        }
                    }
                }

                Section("最近训练") {
                    if app.history.isEmpty {
                        Text("暂无云端训练记录")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(app.history) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(item.totalHits) 拳")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(item.durationSeconds)s")
                                        .foregroundStyle(.secondary)
                                }
                                Text("峰值 \(Int(item.peakForceN)) N | 平均 \(Int(item.avgForceN)) N | \(String(format: "%.1f kcal", item.caloriesBurned))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("云端")
        }
    }
}
