import SwiftUI

struct DeviceView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("连接状态") {
                    HStack {
                        Image(systemName: app.ble.connectedDevice == nil ? "bluetooth.slash" : "bluetooth")
                            .foregroundStyle(app.ble.connectedDevice == nil ? Color.secondary : Color.blue)
                        VStack(alignment: .leading) {
                            Text(app.ble.connectedDevice?.name ?? "未连接")
                            Text(app.ble.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if app.ble.connectedDevice != nil {
                        Button(role: .destructive) {
                            app.ble.disconnect()
                        } label: {
                            Label("断开连接", systemImage: "xmark.circle")
                        }
                    }
                }

                Section {
                    Button {
                        app.ble.startScan()
                    } label: {
                        Label("扫描 SENBALL 设备", systemImage: "magnifyingglass")
                    }
                    Button {
                        app.ble.stopScan()
                    } label: {
                        Label("停止扫描", systemImage: "pause.circle")
                    }
                }

                Section("发现的设备") {
                    if app.ble.devices.isEmpty {
                        Text("没有发现设备。请确认设备已开机并靠近 iPhone。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(app.ble.devices) { device in
                            Button {
                                app.ble.connect(to: device)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(device.name)
                                            .foregroundStyle(.primary)
                                        Text("RSSI \(device.rssi)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("蓝牙设备")
        }
    }
}
