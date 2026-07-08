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
                        palettePanel(palette)
                        languagePanel(palette)
                        trainingPanel(palette)
                        audioPanel(title: "云端音效", assets: app.soundEffects, selectedId: app.selectedSoundEffectId, palette: palette) { asset in
                            app.selectSoundEffect(asset)
                        }
                        audioPanel(title: "背景音乐", assets: app.backgroundMusic, selectedId: app.selectedBackgroundMusicId, palette: palette) { asset in
                            app.selectBackgroundMusic(asset)
                        }
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

    private func palettePanel(_ palette: HitRisePalette) -> some View {
        HitRiseCard(palette: palette) {
            HitRiseSectionTitle(title: "配色选择", subtitle: "保存后立即应用，界面结构保持不变。", palette: palette)
            ForEach(HitRisePalette.all) { option in
                Button {
                    app.updatePalette(option.id)
                } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            ForEach(option.previewColors, id: \.self) { color in
                                Capsule()
                                    .fill(Color(hex: color))
                                    .frame(width: 10, height: 28)
                            }
                        }
                        .frame(width: 48, height: 44)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: palette.cardAlt)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(option.name)
                                .font(.subheadline.weight(.black))
                            Text(option.previewColors.joined(separator: " / "))
                                .font(.caption2)
                                .foregroundStyle(Color(hex: palette.textMuted))
                        }
                        Spacer()
                        if app.selectedPaletteId == option.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(hex: palette.accentHot))
                        }
                    }
                    .foregroundStyle(Color(hex: palette.textPrimary))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: app.selectedPaletteId == option.id ? palette.cardAlt : palette.surfaceBottom))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: app.selectedPaletteId == option.id ? palette.accentHot : palette.stroke), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
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

    private func audioPanel(
        title: String,
        assets: [CloudSoundAsset],
        selectedId: String,
        palette: HitRisePalette,
        select: @escaping (CloudSoundAsset) -> Void
    ) -> some View {
        HitRiseCard(palette: palette) {
            HStack {
                HitRiseSectionTitle(title: title, subtitle: app.audioMessage, palette: palette)
                Spacer()
                Button {
                    Task { await app.refreshAudioCatalogs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color(hex: palette.accentHot))
                }
                .buttonStyle(.plain)
            }
            ForEach(assets) { asset in
                HStack(spacing: 10) {
                    Button {
                        select(asset)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(asset.displayName)
                                    .font(.subheadline.weight(.black))
                                Text(asset.displayDescription)
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: palette.textMuted))
                            }
                            Spacer()
                            if asset.id == selectedId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: palette.accentHot))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(hex: palette.textPrimary))
                    Button {
                        if asset.id != "none" {
                            app.previewAudio(asset)
                        }
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(Color(hex: asset.id == "none" ? palette.textMuted : palette.accentHot))
                    }
                    .buttonStyle(.plain)
                    .disabled(asset.id == "none")
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: asset.id == selectedId ? palette.cardAlt : palette.surfaceBottom))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: asset.id == selectedId ? palette.accentHot : palette.stroke), lineWidth: 1))
                )
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
