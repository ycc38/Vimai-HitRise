import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        TabView {
            TrainingDashboardView()
                .tabItem {
                    Label("训练", systemImage: "figure.boxing")
                }

            DeviceView()
                .tabItem {
                    Label("设备", systemImage: "dot.radiowaves.left.and.right")
                }

            CloudCenterView()
                .tabItem {
                    Label("云端", systemImage: "cloud")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
