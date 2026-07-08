import SwiftUI

struct SettingsView: View {
    var body: some View {
        HitRiseSettingsView()
    }
}

struct HitRiseSettingsView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingTrainingSetup = false

    var body: some View {
        let palette = app.palette
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: palette.backgroundTop), Color(hex: palette.backgroundBottom)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        BluetoothPanel()
                        languagePanel(palette)
                        trainingPanel(palette)
                        appPanel(palette)
                    }
                    .padding()
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingTrainingSetup) {
            TrainingSetupView()
                .environmentObject(app)
        }
        .preferredColorScheme(palette.isLight ? .light : .dark)
    }

    private func languagePanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette) {
            HitRiseSectionTitle(title: "APP 语言", subtitle: "首版中文优先，其他语言保留入口。", palette: palette)
            Picker("语言", selection: Binding(get: { app.selectedLanguage }, set: { app.updateLanguage($0) })) {
                Text("简体中文").tag("zh")
                Text("English").tag("en")
                Text("Français").tag("fr")
                Text("ไทย").tag("th")
            }
            .pickerStyle(.segmented)
        }
    }

    private func trainingPanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette) {
            HitRiseSectionTitle(title: "训练设置", subtitle: "当前 \(app.training.selectedSetup.label) | \(app.training.selectedSetup.rhythmMode.title) | \(app.training.selectedSetup.bpm) BPM", palette: palette)
            HitRiseActionButton(title: "打开训练设置", systemImage: "slider.horizontal.3", palette: palette, fill: palette.accentHot) {
                showingTrainingSetup = true
            }
        }
    }

    private func appPanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette) {
            HitRiseSectionTitle(title: "应用信息", subtitle: "智能拳击速度球 | com.zclei.hitrise", palette: palette)
            Text(app.config.apiBaseURL.absoluteString)
                .font(.caption.monospaced())
                .foregroundStyle(Color(hex: palette.warning))
            NavigationLink("隐私政策摘要") {
                LegalTextView(title: "隐私政策摘要", text: LegalCopy.privacySummary, palette: palette)
            }
            NavigationLink("用户协议摘要") {
                LegalTextView(title: "用户协议摘要", text: LegalCopy.userAgreementSummary, palette: palette)
            }
        }
        .foregroundStyle(Color(hex: palette.textPrimary))
    }
}

private struct LegalTextView: View {
    let title: String
    let text: String
    let palette: HitRisePalette

    var body: some View {
        ScrollView {
            Text(text)
                .foregroundStyle(Color(hex: palette.textSecondary))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(hex: palette.backgroundBottom))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
