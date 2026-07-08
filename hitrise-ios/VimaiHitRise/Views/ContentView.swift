import Foundation
import SwiftUI

struct HitRisePalette: Identifiable, Equatable {
    let id: String
    let name: String
    let previewColors: [String]
    let backgroundTop: String
    let backgroundBottom: String
    let surfaceTop: String
    let surfaceBottom: String
    let card: String
    let cardAlt: String
    let stroke: String
    let strokeStrong: String
    let textPrimary: String
    let textSecondary: String
    let textMuted: String
    let accent: String
    let accentSoft: String
    let accentHot: String
    let button: String
    let buttonText: String
    let success: String
    let warning: String
    let danger: String
    let forceLow: String
    let forceMid: String
    let forceHigh: String

    static let defaultId = "current"

    static let all: [HitRisePalette] = [
        HitRisePalette(id: "current", name: "当前 APP 配色", previewColors: ["#F0FFFB", "#10BDAA", "#FF8A32"], backgroundTop: "#F0FFFB", backgroundBottom: "#E8FFF8", surfaceTop: "#FFFFFF", surfaceBottom: "#F7FFFD", card: "#FFFFFF", cardAlt: "#EFFFFA", stroke: "#CDEFE8", strokeStrong: "#8BEDE2", textPrimary: "#17343B", textSecondary: "#557A7D", textMuted: "#7FA0A3", accent: "#10BDAA", accentSoft: "#DFFFF7", accentHot: "#FF8A32", button: "#10BDAA", buttonText: "#FFFFFF", success: "#16C8B5", warning: "#FFD060", danger: "#E65A4F", forceLow: "#BFEFE5", forceMid: "#FFB347", forceHigh: "#C83A42"),
        HitRisePalette(id: "p01", name: "藏蓝粉紫", previewColors: ["#063C85", "#F7C3D9", "#BB5799"], backgroundTop: "#020613", backgroundBottom: "#09030A", surfaceTop: "#14214A", surfaceBottom: "#060817", card: "#121A38", cardAlt: "#171C29", stroke: "#5E4D85", strokeStrong: "#F7C3D9", textPrimary: "#FFF1FA", textSecondary: "#F7C3D9", textMuted: "#B9B7D0", accent: "#F7C3D9", accentSoft: "#FFD7EA", accentHot: "#BB5799", button: "#BB5799", buttonText: "#070817", success: "#8FD8FF", warning: "#F7C3D9", danger: "#7A2E5F", forceLow: "#7BB4FF", forceMid: "#F7C3D9", forceHigh: "#BB5799"),
        HitRisePalette(id: "p02", name: "晴空橙光", previewColors: ["#1387C0", "#FAEDD1", "#F4520D"], backgroundTop: "#031018", backgroundBottom: "#050404", surfaceTop: "#1A3039", surfaceBottom: "#071014", card: "#112A34", cardAlt: "#17313C", stroke: "#5C7F8F", strokeStrong: "#FAEDD1", textPrimary: "#FFF7E8", textSecondary: "#FAEDD1", textMuted: "#B8C8C9", accent: "#1387C0", accentSoft: "#FAEDD1", accentHot: "#F4520D", button: "#F4520D", buttonText: "#071014", success: "#66D9FF", warning: "#FAEDD1", danger: "#8F321C", forceLow: "#1387C0", forceMid: "#FFAF57", forceHigh: "#F4520D"),
        HitRisePalette(id: "p03", name: "麦浪青野", previewColors: ["#F1ECE0", "#117C0D", "#FAC75E"], backgroundTop: "#031307", backgroundBottom: "#040603", surfaceTop: "#1B2D20", surfaceBottom: "#071308", card: "#14271A", cardAlt: "#1C3322", stroke: "#6B7F36", strokeStrong: "#FAC75E", textPrimary: "#FFF7E8", textSecondary: "#F1ECE0", textMuted: "#B7C7AA", accent: "#117C0D", accentSoft: "#F1ECE0", accentHot: "#FAC75E", button: "#FAC75E", buttonText: "#061306", success: "#87E184", warning: "#FAC75E", danger: "#7A2D18", forceLow: "#117C0D", forceMid: "#6BBF36", forceHigh: "#FAC75E"),
        HitRisePalette(id: "p04", name: "古纸金红", previewColors: ["#F0DEBF", "#F6C12C", "#B22A2A"], backgroundTop: "#0B0503", backgroundBottom: "#020202", surfaceTop: "#34231B", surfaceBottom: "#120805", card: "#2B1A15", cardAlt: "#362018", stroke: "#8A6724", strokeStrong: "#F6C12C", textPrimary: "#FFF1D8", textSecondary: "#F0DEBF", textMuted: "#D7BFA0", accent: "#F6C12C", accentSoft: "#F0DEBF", accentHot: "#B22A2A", button: "#B22A2A", buttonText: "#160806", success: "#F6C12C", warning: "#F6C12C", danger: "#762020", forceLow: "#F0DEBF", forceMid: "#F6C12C", forceHigh: "#B22A2A"),
        HitRisePalette(id: "p05", name: "紫橙竞技", previewColors: ["#97A0E1", "#EB814D"], backgroundTop: "#171736", backgroundBottom: "#0A0717", surfaceTop: "#353A75", surfaceBottom: "#151331", card: "#24285A", cardAlt: "#30356E", stroke: "#7479BF", strokeStrong: "#EB814D", textPrimary: "#FFF7EF", textSecondary: "#E6E9FF", textMuted: "#C5C8EE", accent: "#97A0E1", accentSoft: "#DCE0FF", accentHot: "#EB814D", button: "#EB814D", buttonText: "#1B1020", success: "#DCE0FF", warning: "#EB814D", danger: "#8F3722", forceLow: "#97A0E1", forceMid: "#F0B16A", forceHigh: "#EB814D"),
        HitRisePalette(id: "p06", name: "紫金奖牌", previewColors: ["#983C93", "#EEB832"], backgroundTop: "#1B0821", backgroundBottom: "#08040B", surfaceTop: "#3A1640", surfaceBottom: "#15061A", card: "#2B1232", cardAlt: "#37183D", stroke: "#6D3670", strokeStrong: "#EEB832", textPrimary: "#FFF4E0", textSecondary: "#F3D77A", textMuted: "#C7ADD0", accent: "#983C93", accentSoft: "#F2D37A", accentHot: "#EEB832", button: "#EEB832", buttonText: "#1A0617", success: "#F2D37A", warning: "#EEB832", danger: "#6D1E3B", forceLow: "#B68FD2", forceMid: "#EEB832", forceHigh: "#983C93"),
        HitRisePalette(id: "p07", name: "深紫蓝", previewColors: ["#524887", "#545DB8"], backgroundTop: "#09091E", backgroundBottom: "#04040A", surfaceTop: "#25264B", surfaceBottom: "#0C0C24", card: "#1A1B3A", cardAlt: "#22254A", stroke: "#444B86", strokeStrong: "#7C86FF", textPrimary: "#F6F4FF", textSecondary: "#D9DBFF", textMuted: "#AEB4DA", accent: "#545DB8", accentSoft: "#B8C0FF", accentHot: "#7C86FF", button: "#545DB8", buttonText: "#070817", success: "#8FD8FF", warning: "#B8C0FF", danger: "#6B2F66", forceLow: "#7BA6FF", forceMid: "#B8C0FF", forceHigh: "#545DB8"),
        HitRisePalette(id: "p08", name: "蓝紫丁香", previewColors: ["#4E50A5", "#B68FD2"], backgroundTop: "#0B0B24", backgroundBottom: "#050511", surfaceTop: "#25285C", surfaceBottom: "#0D0E2A", card: "#1C1E48", cardAlt: "#282A5A", stroke: "#55589A", strokeStrong: "#B68FD2", textPrimary: "#F8F2FF", textSecondary: "#E5D2FF", textMuted: "#BDB7D8", accent: "#4E50A5", accentSoft: "#D7B8F0", accentHot: "#B68FD2", button: "#B68FD2", buttonText: "#090817", success: "#C7D4FF", warning: "#D7B8F0", danger: "#5E2F77", forceLow: "#7BA6FF", forceMid: "#B68FD2", forceHigh: "#4E50A5")
    ]

    static func byId(_ id: String) -> HitRisePalette {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    var isLight: Bool { id == Self.defaultId }
}

enum HitRiseHomePage: String, CaseIterable, Identifiable {
    case training
    case achievements
    case leaderboard
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .training: return "训练中心"
        case .achievements: return "锻炼成果"
        case .leaderboard: return "榜单排名"
        case .profile: return "个人中心"
        }
    }

    var icon: String {
        switch self {
        case .training: return "figure.boxing"
        case .achievements: return "star.fill"
        case .leaderboard: return "list.number"
        case .profile: return "person.fill"
        }
    }

    func assetIcon(selected: Bool) -> String {
        switch self {
        case .training: return selected ? "home_nav_training_selected" : "home_nav_training"
        case .achievements: return selected ? "home_nav_achievements_selected" : "home_nav_achievements"
        case .leaderboard: return selected ? "home_nav_leaderboard_selected" : "home_nav_leaderboard"
        case .profile: return selected ? "home_nav_profile_selected" : "home_nav_profile"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var selectedPage: HitRiseHomePage = .training
    @State private var showingSettings = false
    @State private var showingLaunchSplash = true

    var body: some View {
        let palette = app.palette
        ZStack {
            LinearGradient(
                colors: [Color(hex: palette.backgroundTop), Color(hex: palette.backgroundBottom)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                pageHost
                HitRiseBottomNav(selectedPage: $selectedPage, palette: palette)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            if showingLaunchSplash {
                HitRiseLaunchSplashView {
                    dismissLaunchSplash()
                }
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
                .zIndex(20)
            }
        }
        .preferredColorScheme(palette.isLight ? .light : .dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                dismissLaunchSplash()
            }
        }
        .sheet(isPresented: $showingSettings) {
            HitRiseSettingsView()
                .environmentObject(app)
        }
    }

    @ViewBuilder
    private var pageHost: some View {
        switch selectedPage {
        case .training:
            TrainingDashboardView(onSettings: {
                showingSettings = true
            })
        case .achievements:
            AchievementsHistoryView()
        case .leaderboard:
            LeaderboardView()
        case .profile:
            ProfileView()
        }
    }

    private func dismissLaunchSplash() {
        guard showingLaunchSplash else { return }
        withAnimation(.easeInOut(duration: 0.32)) {
            showingLaunchSplash = false
        }
    }
}

struct HitRiseLaunchSplashView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#140800")
                .ignoresSafeArea()

            Image("home_banner")
                .resizable()
                .scaledToFill()
                .opacity(0.36)
                .ignoresSafeArea()

            VStack {
                LinearGradient(
                    colors: [Color(hex: "#08111A").opacity(0.90), Color(hex: "#06001A").opacity(0.07)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                Spacer()
                LinearGradient(
                    colors: [Color(hex: "#08111A").opacity(0.95), Color(hex: "#06001A").opacity(0.07)],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 260)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                Text("HITRISE")
                    .font(.system(size: 16, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(Color(hex: "#FFF8E8"))
                Text("智能拳击球训练")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#CAA26A"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 42)
            .padding(.horizontal, 26)

            Image("wavemill_logo")
                .resizable()
                .scaledToFit()
                .padding(18)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(hex: "#F7FBFF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color(hex: "#BFEFF7F3"), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                )
                .padding(.horizontal, 24)

            Text("轻触跳过")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#B88A54"))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 34)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
    }
}

struct HitRiseHeader: View {
    @EnvironmentObject private var app: AppViewModel
    let selectedPage: HitRiseHomePage
    let palette: HitRisePalette
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("智能拳击速度球")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: palette.textPrimary))
                HStack(spacing: 8) {
                    Image(systemName: app.ble.connectedDevice == nil ? "bluetooth.slash" : "dot.radiowaves.left.and.right")
                        .foregroundStyle(app.ble.connectedDevice == nil ? Color(hex: "#FF4A6A") : Color(hex: "#2E8BFF"))
                    Text(app.ble.connectedDevice?.name ?? selectedPage.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: palette.textSecondary))
                        .lineLimit(1)
                    Text(app.ble.latestTelemetry?.batteryText ?? "--")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(hex: palette.textPrimary))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: palette.cardAlt)))
                }
            }
            Spacer()
            Button(action: onSettings) {
                Image("home_icon_settings")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color(hex: palette.isLight ? "#FFFFFF" : palette.card)))
                    .overlay(Circle().stroke(Color(hex: palette.stroke), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

struct HitRiseBottomNav: View {
    @Binding var selectedPage: HitRiseHomePage
    let palette: HitRisePalette

    var body: some View {
        HStack(spacing: 6) {
            ForEach(HitRiseHomePage.allCases) { page in
                Button {
                    selectedPage = page
                } label: {
                    VStack(spacing: 4) {
                        Image(page.assetIcon(selected: selectedPage == page))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        Text(page.title)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundStyle(selectedPage == page ? Color(hex: "#09A99A") : Color(hex: "#6B7C80"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(selectedPage == page ? Color(hex: "#EFFFFA") : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: palette.isLight ? "#FFFFFF" : palette.surfaceTop))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: palette.isLight ? "#DDF4EF" : palette.stroke), lineWidth: 1))
                .shadow(color: Color.black.opacity(palette.isLight ? 0.10 : 0.35), radius: 14, x: 0, y: 6)
        )
    }
}

struct HitRiseCard<Content: View>: View {
    let palette: HitRisePalette
    var stroke: String?
    var fill: String?
    var padding: CGFloat = 16
    private let content: Content

    init(
        palette: HitRisePalette,
        stroke: String? = nil,
        fill: String? = nil,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.stroke = stroke
        self.fill = fill
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: fill ?? palette.surfaceTop), Color(hex: palette.surfaceBottom)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(hex: stroke ?? palette.stroke), lineWidth: 1)
                )
        )
    }
}

struct HitRiseBadge: View {
    let text: String
    let palette: HitRisePalette
    var fill: String?
    var textColor: String?

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(Color(hex: textColor ?? (palette.isLight ? palette.textPrimary : palette.buttonText)))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(hex: fill ?? palette.accentSoft)))
    }
}

struct HitRiseActionButton: View {
    let title: String
    let systemImage: String
    let palette: HitRisePalette
    var fill: String?
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color(hex: palette.buttonText))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: fill ?? palette.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: palette.accentSoft).opacity(0.7), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}

struct HitRiseMetricTile: View {
    let title: String
    let value: String
    let unit: String
    let palette: HitRisePalette
    var accent: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color(hex: palette.textMuted))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: accent ?? palette.textPrimary))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                Text(unit)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(hex: palette.textMuted))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: palette.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hex: palette.stroke), lineWidth: 1))
        )
    }
}

struct HitRiseSectionTitle: View {
    let title: String
    let subtitle: String?
    let palette: HitRisePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(Color(hex: palette.textPrimary))
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(hex: palette.textMuted))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Color {
    init(hex: String) {
        var value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
