import CoreBluetooth
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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("蓝牙连接")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#19C5B7"))
                Text("请先扫描 SENBALL# 设备，连接成功后即可开始训练。")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#557A7D"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(statusTitle)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "#17343B"))
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(hex: "#F3FFFC"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color(hex: "#CBEFE7"), lineWidth: 1.4)
                        )
                        .shadow(color: Color.black.opacity(0.10), radius: 7, x: 0, y: 4)
                )

            HStack(spacing: 10) {
                bluetoothButton(
                    title: "扫描",
                    fill: LinearGradient(colors: [Color(hex: "#67E5DC"), Color(hex: "#13BFAF")], startPoint: .leading, endPoint: .trailing),
                    foreground: .white,
                    disabled: app.ble.connectedDevice != nil
                ) {
                    selectedDeviceId = nil
                    app.ble.startScan()
                }

                bluetoothButton(
                    title: "连接",
                    fill: LinearGradient(colors: [Color.white, Color.white], startPoint: .leading, endPoint: .trailing),
                    foreground: Color(hex: "#8AA0A1"),
                    disabled: app.ble.connectedDevice != nil || selectedDevice == nil
                ) {
                    if let selectedDevice {
                        app.ble.connect(to: selectedDevice)
                    }
                }

                bluetoothButton(
                    title: "断开",
                    fill: LinearGradient(colors: [Color(hex: "#F8C8C4"), Color(hex: "#F0A5A0")], startPoint: .leading, endPoint: .trailing),
                    foreground: .white,
                    disabled: app.ble.connectedDevice == nil
                ) {
                    app.ble.disconnect()
                }
            }

            deviceList

            if let telemetry = app.ble.latestTelemetry, app.ble.connectedDevice != nil {
                HStack(spacing: 10) {
                    bluetoothMetric("电量", value: telemetry.batteryText)
                    bluetoothMetric("计数", value: "\(telemetry.hitCount)")
                }
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
                .shadow(color: Color(hex: "#5BCBBC").opacity(0.20), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            selectDefaultDeviceIfNeeded()
        }
        .onChange(of: app.ble.devices) { _ in
            selectDefaultDeviceIfNeeded()
        }
    }

    private var deviceList: some View {
        VStack(spacing: 10) {
            if visibleDevices.isEmpty {
                Text("未扫描到 SENBALL# 设备")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "#557A7D"))
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(hex: "#F5FFFC"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color(hex: "#CBEFE7"), lineWidth: 1.3)
                            )
                    )
            } else {
                ForEach(visibleDevices) { device in
                    deviceRow(device)
                }
            }
        }
    }

    private var statusTitle: String {
        if let device = app.ble.connectedDevice {
            return "蓝牙已连接 \(device.name)"
        }
        if app.ble.bluetoothState != .poweredOn {
            return "蓝牙未开启"
        }
        return "蓝牙已断开"
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

    private func selectDefaultDeviceIfNeeded() {
        guard selectedDeviceId == nil else { return }
        selectedDeviceId = visibleDevices.first(where: { $0.isLikelySensorBall })?.id ?? visibleDevices.first?.id
    }

    private func bluetoothButton(
        title: String,
        fill: LinearGradient,
        foreground: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    Capsule()
                        .fill(fill)
                        .overlay(Capsule().stroke(Color(hex: "#E2F2EF"), lineWidth: 1))
                        .shadow(color: Color.black.opacity(title == "扫描" ? 0.14 : 0.08), radius: 7, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.54 : 1)
    }

    private func bluetoothMetric(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color(hex: "#7FA0A3"))
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(Color(hex: "#17343B"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#F5FFFC"))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#D6F2EC"), lineWidth: 1))
        )
    }

    private func deviceRow(_ device: SensorBallDeviceInfo) -> some View {
        let selected = selectedDeviceId == device.id || app.ble.connectedDevice?.id == device.id
        return Button {
            selectedDeviceId = device.id
            app.ble.stopScan()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(device.name)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: selected ? "#FFFFFF" : "#17343B"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(device.detail.isEmpty ? "BLE" : device.detail) | RSSI \(device.rssi)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: selected ? "#EFFFFA" : "#557A7D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        selected
                            ? LinearGradient(colors: [Color(hex: "#67E5DC"), Color(hex: "#13BFAF")], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(hex: "#F5FFFC"), Color(hex: "#F5FFFC")], startPoint: .leading, endPoint: .trailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(hex: selected ? "#8CF4EA" : "#CBEFE7"), lineWidth: 1.3)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
