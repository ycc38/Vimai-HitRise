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
                    Text(app.localized("云端训练记录与排行榜", "Cloud Training Records & Leaderboard", "Historique cloud et classement", "บันทึกการฝึกบนคลาวด์และกระดานจัดอันดับ"))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#19C5B7"))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(draftCloudEnabled
                        ? app.localized("已允许上传匿名资料和训练成绩", "Anonymous profile and training results may be uploaded", "Profil anonyme et résultats autorisés à l'envoi", "อนุญาตให้อัปโหลดโปรไฟล์ไม่ระบุตัวตนและผลการฝึกแล้ว")
                        : app.localized("训练成绩仅保留在本地，不会上传", "Training results stay on this device and are not uploaded", "Les résultats restent sur cet appareil et ne sont pas envoyés", "ผลการฝึกเก็บไว้ในเครื่องนี้เท่านั้น ไม่มีการอัปโหลด"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#557A7D"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: $draftCloudEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "#10BDAA"))
            }

            Text(app.localized(
                "开启后，App 会将匿名用户编号、昵称、训练成绩和统计数据上传至 HitRise 服务器，用于云端历史、成就、个人资料和排行榜；排行榜可能公开昵称、段位和成绩。",
                "When enabled, the app uploads your anonymous user ID, nickname, training results, and stats to the HitRise server for cloud history, achievements, profile, and leaderboards. Leaderboards may show your nickname, rank, and scores publicly.",
                "Une fois activé, l'app envoie votre identifiant anonyme, votre pseudo, vos résultats et statistiques au serveur HitRise pour l'historique cloud, les succès, le profil et les classements. Les classements peuvent afficher publiquement votre pseudo, votre rang et vos scores.",
                "เมื่อเปิดใช้ แอปจะอัปโหลดรหัสผู้ใช้แบบไม่ระบุตัวตน ชื่อเล่น ผลการฝึก และสถิติไปยังเซิร์ฟเวอร์ HitRise สำหรับประวัติบนคลาวด์ ความสำเร็จ โปรไฟล์ และกระดานจัดอันดับ ซึ่งอาจแสดงชื่อเล่น ระดับ และคะแนนของคุณต่อสาธารณะ"
            ))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#557A7D"))
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://ycc38.github.io/Vimai-HitRise/privacy.html")!) {
                Label(app.localized("查看隐私政策", "View Privacy Policy", "Voir la politique de confidentialité", "ดูนโยบายความเป็นส่วนตัว"), systemImage: "doc.text")
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
            Text(app.localized("蓝牙与语言设置", "Bluetooth & Language", "Bluetooth et langue", "บลูทูธและภาษา"))
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "#17343B"))
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(app.localized("连接 SENBALL# 设备，并选择 APP 显示语言。", "Connect your SENBALL# device and choose the app language.", "Connectez votre appareil SENBALL# et choisissez la langue de l'app.", "เชื่อมต่ออุปกรณ์ SENBALL# และเลือกภาษาของแอป"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "#557A7D"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
    }

    private var languagePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(app.localized("APP 语言", "App Language", "Langue de l'app", "ภาษาแอป"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#19C5B7"))
                Text(app.localized("界面和训练提示会按照这里的语言显示。", "The interface and training cues will use this language.", "L'interface et les conseils d'entraînement utiliseront cette langue.", "หน้าจอและคำแนะนำการฝึกจะแสดงเป็นภาษานี้"))
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
                Text(app.localized("取消", "Cancel", "Annuler", "ยกเลิก"))
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
                Text(app.localized("保存", "Save", "Enregistrer", "บันทึก"))
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
