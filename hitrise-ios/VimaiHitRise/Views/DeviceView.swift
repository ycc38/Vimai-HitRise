import SwiftUI

struct DeviceView: View {
    var body: some View {
        ScrollView {
            BluetoothPanel()
                .padding()
        }
    }
}

struct BluetoothPanel: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var selectedDeviceId: UUID?

    var body: some View {
        let palette = app.palette
        HitRiseCard(palette: palette, stroke: palette.strokeStrong, fill: palette.card) {
            HitRiseSectionTitle(
                title: "蓝牙连接",
                subtitle: "请先扫描 SENBALL# 设备，连接成功后即可开始训练。",
                palette: palette
            )
            Text(statusText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: palette.textSecondary))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: palette.cardAlt))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: palette.stroke), lineWidth: 1))
                )

            HStack(spacing: 8) {
                bluetoothMetric("电量", value: app.ble.latestTelemetry?.batteryText ?? "--", palette: palette)
                bluetoothMetric("计数", value: app.ble.latestTelemetry.map { "\($0.hitCount)" } ?? "--", palette: palette)
            }

            HStack(spacing: 8) {
                HitRiseActionButton(title: "扫描", systemImage: "magnifyingglass", palette: palette, fill: palette.button, disabled: app.ble.connectedDevice != nil) {
                    selectedDeviceId = nil
                    app.ble.startScan()
                }
                HitRiseActionButton(title: "连接", systemImage: "link", palette: palette, fill: palette.surfaceTop, disabled: app.ble.connectedDevice != nil || selectedDevice == nil) {
                    if let selectedDevice {
                        app.ble.connect(to: selectedDevice)
                    }
                }
                HitRiseActionButton(title: "断开", systemImage: "xmark.circle", palette: palette, fill: palette.danger, disabled: app.ble.connectedDevice == nil) {
                    app.ble.disconnect()
                }
            }

            VStack(spacing: 8) {
                if visibleDevices.isEmpty {
                    Text("没有发现设备。请确认设备已开机、靠近 iPhone，并先退出安卓端连接。")
                        .font(.caption)
                        .foregroundStyle(Color(hex: palette.textMuted))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                } else {
                    ForEach(visibleDevices) { device in
                        deviceRow(device, palette: palette)
                    }
                }
            }

            if !app.ble.lastScanDebugText.isEmpty {
                Text(app.ble.lastScanDebugText)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: palette.textMuted))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onChange(of: app.ble.devices) { devices in
            if selectedDeviceId == nil {
                selectedDeviceId = devices.first(where: { $0.isLikelySensorBall })?.id ?? devices.first?.id
            }
        }
    }

    private var statusText: String {
        var text = app.ble.statusMessage
        if let device = app.ble.connectedDevice {
            text += " | \(device.name)"
        }
        return text
    }

    private var visibleDevices: [SensorBallDeviceInfo] {
        var result = app.ble.devices
        if let connected = app.ble.connectedDevice, result.contains(where: { $0.id == connected.id }) == false {
            result.insert(connected, at: 0)
        }
        return result
    }

    private var selectedDevice: SensorBallDeviceInfo? {
        let id = selectedDeviceId
        return visibleDevices.first(where: { $0.id == id }) ?? visibleDevices.first
    }

    private func bluetoothMetric(_ label: String, value: String, palette: HitRisePalette) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color(hex: palette.textMuted))
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(Color(hex: palette.textPrimary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: palette.cardAlt))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: palette.stroke), lineWidth: 1))
        )
    }

    private func deviceRow(_ device: SensorBallDeviceInfo, palette: HitRisePalette) -> some View {
        let selected = selectedDeviceId == device.id || app.ble.connectedDevice?.id == device.id
        return Button {
            selectedDeviceId = device.id
            app.ble.stopScan()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(device.name)
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color(hex: selected ? palette.buttonText : palette.textPrimary))
                        if device.isLikelySensorBall {
                            Text("SENBALL")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Color(hex: selected ? palette.buttonText : palette.accentHot))
                        }
                    }
                    Text("\(device.detail.isEmpty ? "BLE" : device.detail) | RSSI \(device.rssi)")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: selected ? palette.buttonText : palette.textMuted).opacity(selected ? 0.82 : 1))
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(Color(hex: selected ? palette.buttonText : palette.textMuted))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: selected ? palette.accentSoft : palette.cardAlt))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: selected ? palette.accentHot : palette.stroke), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
