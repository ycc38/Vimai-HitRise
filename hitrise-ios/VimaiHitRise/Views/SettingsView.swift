import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("应用") {
                    LabeledContent("名称", value: "Vimai HitRise")
                    LabeledContent("副标题", value: "立式拳击速度球")
                    LabeledContent("Bundle ID", value: "com.zclei.hitrise")
                }

                Section("接口") {
                    Text(app.config.apiBaseURL.absoluteString)
                        .font(.footnote.monospaced())
                    Text("当前开发版继续使用 HTTP 公网 IP。正式上架前建议切换到 HTTPS 域名。")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Section("本机资料") {
                    LabeledContent("用户编号", value: app.identity.serial)
                    LabeledContent("激活模式", value: app.identity.activationToken)
                }

                Section("隐私与权限") {
                    Text("蓝牙权限仅用于连接立式拳击速度球并接收训练数据。训练记录会同步到 HitRise 云端，用于历史记录、排行榜和成就统计。")
                        .font(.subheadline)
                    NavigationLink("隐私政策摘要") {
                        LegalTextView(title: "隐私政策摘要", text: LegalCopy.privacySummary)
                    }
                    NavigationLink("用户协议摘要") {
                        LegalTextView(title: "用户协议摘要", text: LegalCopy.userAgreementSummary)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

private struct LegalTextView: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
