import SwiftUI

struct SettingsView: View {
    var body: some View {
        HitRiseSettingsView()
    }
}

struct HitRiseSettingsView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draftLanguage = "zh"
    @State private var draftCloudEnabled = false

    var onCancel: (() -> Void)?
    var onSave: (() -> Void)?

    init(onCancel: (() -> Void)? = nil, onSave: (() -> Void)? = nil) {
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture {
                    cancel()
                }

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        BluetoothPanel()
                        cloudSyncPanel
                        languagePanel
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .padding(.bottom, 18)
                }
                .scrollIndicators(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(Color(hex: "#F4FFFC"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(Color(hex: "#8FE5D8"), lineWidth: 1.4)
                        )
                        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 10)
                )
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

                actionButtons
            }
            .frame(maxWidth: 430)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 14)
            .padding(.top, 22)
            .padding(.bottom, 24)
        }
        .onAppear {
            draftLanguage = app.selectedLanguage
            draftCloudEnabled = app.hasCloudConsent
        }
    }

    private var cloudSyncPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("云端训练记录与排行榜")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#19C5B7"))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(draftCloudEnabled ? "已允许上传匿名资料和训练成绩" : "训练成绩仅保留在本地，不会上传")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#557A7D"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: $draftCloudEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "#10BDAA"))
            }

            Text("开启后，App 会将匿名用户编号、昵称、训练成绩和统计数据上传至 HitRise 服务器，用于云端历史、成就、个人资料和排行榜；排行榜可能公开昵称、段位和成绩。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#557A7D"))
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://ycc38.github.io/Vimai-HitRise/privacy.html")!) {
                Label("查看隐私政策", systemImage: "doc.text")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "#087F75"))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color(hex: "#CBEFE7"), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "#5BCBBC").opacity(0.18), radius: 10, x: 0, y: 5)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("蓝牙与语言设置")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "#17343B"))
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text("连接 SENBALL# 设备，并选择 APP 显示语言。")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "#557A7D"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
    }

    private var languagePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("APP 语言")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#19C5B7"))
                Text("界面和训练提示会按照这里的语言显示。")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#557A7D"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                languageRow(code: "zh", title: "简体中文")
                languageRow(code: "en", title: "English")
                languageRow(code: "fr", title: "Français")
                languageRow(code: "th", title: "ไทย")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color(hex: "#CBEFE7"), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "#5BCBBC").opacity(0.18), radius: 10, x: 0, y: 5)
        )
    }

    private func languageRow(code: String, title: String) -> some View {
        let selected = draftLanguage == code
        return Button {
            draftLanguage = code
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: selected ? "#FFFFFF" : "#20C8BA"), lineWidth: 4)
                        .frame(width: 28, height: 28)
                    if selected {
                        Circle()
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 13, height: 13)
                    }
                }

                Text(title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: selected ? "#FFFFFF" : "#17343B"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        selected
                            ? LinearGradient(
                                colors: [Color(hex: "#67E5DC"), Color(hex: "#10BDAA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white, Color.white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(hex: selected ? "#8CF4EA" : "#CBEFE7"), lineWidth: 1.4)
                    )
                    .shadow(color: Color.black.opacity(selected ? 0.16 : 0.09), radius: 7, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Spacer()
            Button {
                cancel()
            } label: {
                Text("取消")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#17343B"))
                    .frame(width: 92, height: 92)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Color(hex: "#D7F1EC"), lineWidth: 1.2))
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            Button {
                save()
            } label: {
                Text("保存")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(width: 92, height: 92)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#64E7DD"), Color(hex: "#18C4B6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.86), lineWidth: 1.4))
                    .shadow(color: Color(hex: "#18C4B6").opacity(0.36), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func cancel() {
        if let onCancel {
            onCancel()
        } else {
            dismiss()
        }
    }

    private func save() {
        app.updateLanguage(draftLanguage)
        app.setCloudConsent(draftCloudEnabled)
        if let onSave {
            onSave()
        } else {
            dismiss()
        }
    }
}
