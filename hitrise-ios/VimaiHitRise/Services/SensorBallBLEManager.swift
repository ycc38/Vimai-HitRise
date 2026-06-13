import Combine
import CoreBluetooth
import Foundation

final class SensorBallBLEManager: NSObject, ObservableObject {
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var devices: [SensorBallDeviceInfo] = []
    @Published private(set) var connectedDevice: SensorBallDeviceInfo?
    @Published private(set) var latestTelemetry: SensorBallTelemetry?
    @Published var statusMessage: String = "蓝牙未初始化"

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var writableCharacteristic: CBCharacteristic?
    private var pendingGyroCommand: Bool?
    private var writeInFlight = false
    private var notifiedCharacteristicKeys = Set<String>()

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    var isReadyForCounting: Bool {
        connectedDevice != nil && writableCharacteristic != nil && !writeInFlight
    }

    func startScan() {
        guard central.state == .poweredOn else {
            statusMessage = "请先开启蓝牙"
            return
        }
        devices.removeAll()
        peripherals.removeAll()
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        statusMessage = "正在扫描附近 BLE 设备..."
    }

    func stopScan() {
        central.stopScan()
    }

    func connect(to device: SensorBallDeviceInfo) {
        guard let peripheral = peripherals[device.id] else {
            statusMessage = "设备已离线，请重新扫描"
            return
        }
        stopScan()
        writableCharacteristic = nil
        notifiedCharacteristicKeys.removeAll()
        pendingGyroCommand = nil
        writeInFlight = false
        statusMessage = "正在连接 \(device.name)..."
        central.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let id = connectedDevice?.id, let peripheral = peripherals[id] {
            central.cancelPeripheralConnection(peripheral)
        }
        connectedDevice = nil
        writableCharacteristic = nil
        pendingGyroCommand = nil
        writeInFlight = false
    }

    @discardableResult
    func setGyroscopeEnabled(_ enabled: Bool) -> Bool {
        guard let deviceId = connectedDevice?.id,
              let peripheral = peripherals[deviceId],
              let characteristic = writableCharacteristic else {
            statusMessage = "蓝牙计数通道未就绪"
            pendingGyroCommand = enabled
            return false
        }
        if writeInFlight {
            pendingGyroCommand = enabled
            return true
        }
        let payload = SensorBallBLEManager.gyroscopeCommandPayload(enabled: enabled)
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        peripheral.writeValue(payload, for: characteristic, type: type)
        writeInFlight = type == .withResponse
        statusMessage = enabled ? "已发送开启计数指令" : "已发送关闭计数指令"
        if type == .withoutResponse {
            flushPendingGyroCommand()
        }
        return true
    }

    private func flushPendingGyroCommand() {
        guard !writeInFlight, let command = pendingGyroCommand else {
            return
        }
        pendingGyroCommand = nil
        _ = setGyroscopeEnabled(command)
    }

    private func addOrUpdate(peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        let names = SensorBallBLEManager.nameCandidates(from: advertisementData, peripheralName: peripheral.name)
        let matchedName = names.first(where: SensorBallBLEManager.isBoxingDeviceName)
        let hasCompatibleAdvertisement = SensorBallBLEManager.hasCompatibleSerialAdvertisement(advertisementData)
        let isLikelySensorBall = matchedName != nil || hasCompatibleAdvertisement
        peripherals[peripheral.identifier] = peripheral
        let name = matchedName ?? names.first ?? SensorBallBLEManager.fallbackDisplayName(for: peripheral)
        let item = SensorBallDeviceInfo(
            id: peripheral.identifier,
            name: name,
            rssi: rssi.intValue,
            isLikelySensorBall: isLikelySensorBall,
            detail: SensorBallBLEManager.discoveryDetail(
                names: names,
                advertisementData: advertisementData,
                isLikelySensorBall: isLikelySensorBall
            )
        )
        if let index = devices.firstIndex(where: { $0.id == item.id }) {
            devices[index] = item
        } else {
            devices.append(item)
        }
        devices.sort {
            if $0.isLikelySensorBall != $1.isLikelySensorBall {
                return $0.isLikelySensorBall && !$1.isLikelySensorBall
            }
            return $0.rssi > $1.rssi
        }
    }

    private func configure(characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
            if writableCharacteristic == nil || writeScore(characteristic) > writeScore(writableCharacteristic!) {
                writableCharacteristic = characteristic
            }
        }
        if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
            let key = "\(characteristic.service?.uuid.uuidString ?? ""):\(characteristic.uuid.uuidString)"
            guard !notifiedCharacteristicKeys.contains(key),
                  SensorBallBLEManager.isTelemetryNotifyCharacteristic(characteristic) else {
                return
            }
            notifiedCharacteristicKeys.insert(key)
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    private func writeScore(_ characteristic: CBCharacteristic) -> Int {
        let uuid = characteristic.uuid.uuidString.lowercased()
        let service = characteristic.service?.uuid.uuidString.lowercased() ?? ""
        var score = 0
        if uuid.contains("ffe9") { score += 80 }
        if uuid.contains("ffe1") { score += 40 }
        if service.contains("ffe0") { score += 20 }
        if characteristic.properties.contains(.writeWithoutResponse) { score += 8 }
        if characteristic.properties.contains(.write) { score += 4 }
        return score
    }

    static func parseTelemetryPackets(_ data: Data?) -> [SensorBallTelemetry] {
        guard let data, data.count >= Constants.telemetryPacketSize else {
            return []
        }
        let bytes = [UInt8](data)
        var packets: [SensorBallTelemetry] = []
        for index in 0...(bytes.count - Constants.telemetryPacketSize) {
            if bytes[index] == 0xD5, bytes[index + 1] == 0x5D, bytes[index + 2] == 0x03 {
                packets.append(parseTelemetryPacket(bytes, index: index))
            }
        }
        return packets
    }

    private static func parseTelemetryPacket(_ bytes: [UInt8], index: Int) -> SensorBallTelemetry {
        let gyroForceRaw = Int(bytes[index + 7])
        let pressureForceRaw = Int(bytes[index + 8])
        let forceLow = Int(bytes[index + 9])
        let forceHigh = Int(bytes[index + 10])
        let protocolForceN = forceLow | (forceHigh << 8)
        let rawForceN = protocolForceN > 0 ? protocolForceN : max(gyroForceRaw, pressureForceRaw)
        let forceN = Int((Double(rawForceN) * Constants.sensorForceScale).rounded())
        return SensorBallTelemetry(
            packetIndex: Int(bytes[index + 3]),
            batteryRaw: Int(bytes[index + 4]),
            hitCount: Int(bytes[index + 5]),
            pressureHitCount: Int(bytes[index + 6]),
            gyroForceRaw: gyroForceRaw,
            pressureForceRaw: pressureForceRaw,
            forceLow: forceLow,
            forceHigh: forceHigh,
            forceN: forceN
        )
    }

    private static func gyroscopeCommandPayload(enabled: Bool) -> Data {
        Data([0xC5, 0x5C, 0x04, enabled ? 0x01 : 0x00])
    }

    private static func isTelemetryNotifyCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        let uuid = characteristic.uuid.uuidString.lowercased()
        let service = characteristic.service?.uuid.uuidString.lowercased() ?? ""
        if uuid.contains("2a05") {
            return false
        }
        return uuid.contains("ffe4") || service.contains("ffe0") || service.contains("ffe5")
    }

    static func isBoxingDeviceName(_ name: String) -> Bool {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty,
              normalized.range(of: Constants.deviceBrand, options: [.caseInsensitive]) != nil else {
            return false
        }
        return true
    }

    private static func nameCandidates(from advertisementData: [String: Any], peripheralName: String?) -> [String] {
        var candidates: [String] = []
        appendCandidate(advertisementData[CBAdvertisementDataLocalNameKey] as? String, to: &candidates)
        appendCandidate(peripheralName, to: &candidates)
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            appendCandidate(extractBoxingName(from: manufacturerData), to: &candidates)
        }
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            serviceData.values.forEach { data in
                appendCandidate(extractBoxingName(from: data), to: &candidates)
            }
        }
        return candidates
    }

    private static func appendCandidate(_ candidate: String?, to candidates: inout [String]) {
        guard let candidate = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
              !candidate.isEmpty,
              !candidates.contains(where: { $0.compare(candidate, options: .caseInsensitive) == .orderedSame }) else {
            return
        }
        candidates.append(candidate)
    }

    private static func extractBoxingName(from data: Data) -> String? {
        let texts = [
            String(data: data, encoding: .utf8),
            String(data: data, encoding: .isoLatin1)
        ].compactMap { $0 }
        for text in texts {
            if let name = extractBoxingName(from: text) {
                return name
            }
        }
        return nil
    }

    private static func extractBoxingName(from text: String) -> String? {
        guard let range = text.range(of: Constants.deviceBrand, options: .caseInsensitive) else {
            return nil
        }
        var end = range.lowerBound
        while end < text.endIndex, isDeviceNameCharacter(text[end]) {
            end = text.index(after: end)
        }
        let name = String(text[range.lowerBound..<end])
        return isBoxingDeviceName(name) ? name : nil
    }

    private static func isDeviceNameCharacter(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 else {
            return false
        }
        let value = Int(scalar.value)
        return (65...90).contains(value) ||
            (97...122).contains(value) ||
            (48...57).contains(value) ||
            character == "#" ||
            character == "_" ||
            character == "-"
    }

    private static func hasCompatibleSerialAdvertisement(_ advertisementData: [String: Any]) -> Bool {
        let uuidCollections = [
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
            advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID],
            advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
        ]
        if uuidCollections.compactMap({ $0 }).flatMap({ $0 }).contains(where: { isCompatibleSerialUUID($0) }) {
            return true
        }
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            return serviceData.keys.contains(where: { isCompatibleSerialUUID($0) }) ||
                serviceData.values.contains(where: { extractBoxingName(from: $0) != nil })
        }
        return false
    }

    private static func discoveryDetail(
        names: [String],
        advertisementData: [String: Any],
        isLikelySensorBall: Bool
    ) -> String {
        var parts = [isLikelySensorBall ? "SENBALL/BLE" : "BLE"]
        if let name = names.first, !name.isEmpty {
            parts.append(name)
        }
        let uuids = advertisedServiceUUIDs(from: advertisementData)
        if !uuids.isEmpty {
            parts.append(uuids.prefix(3).joined(separator: ","))
        }
        return parts.joined(separator: " | ")
    }

    private static func advertisedServiceUUIDs(from advertisementData: [String: Any]) -> [String] {
        var uuids: [CBUUID] = []
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            uuids.append(contentsOf: serviceUUIDs)
        }
        if let overflowUUIDs = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] {
            uuids.append(contentsOf: overflowUUIDs)
        }
        if let solicitedUUIDs = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] {
            uuids.append(contentsOf: solicitedUUIDs)
        }
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            uuids.append(contentsOf: serviceData.keys)
        }
        return uuids.map(\.uuidString)
    }

    private static func isCompatibleSerialUUID(_ uuid: CBUUID) -> Bool {
        let text = uuid.uuidString.lowercased()
        return text.contains("ffe0") || text.contains("ffe1") || text.contains("ffe4") || text.contains("ffe5") || text.contains("ffe9")
    }

    private static func fallbackDisplayName(for peripheral: CBPeripheral) -> String {
        "SENBALL BLE \(peripheral.identifier.uuidString.prefix(4))"
    }

    private enum Constants {
        static let deviceBrand = "SENBALL"
        static let telemetryPacketSize = 11
        static let sensorForceScale = 0.6
    }
}

extension SensorBallBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        switch central.state {
        case .poweredOn:
            statusMessage = "蓝牙已开启"
        case .poweredOff:
            statusMessage = "蓝牙已关闭"
        case .unauthorized:
            statusMessage = "蓝牙权限未授权"
        case .unsupported:
            statusMessage = "当前设备不支持 BLE"
        default:
            statusMessage = "蓝牙状态初始化中"
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        addOrUpdate(peripheral: peripheral, rssi: RSSI, advertisementData: advertisementData)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectedDevice = devices.first(where: { $0.id == peripheral.identifier })
            ?? SensorBallDeviceInfo(id: peripheral.identifier, name: peripheral.name ?? "SENBALL", rssi: 0)
        statusMessage = "已连接，正在发现服务..."
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusMessage = "连接失败：\(error?.localizedDescription ?? "未知错误")"
        connectedDevice = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusMessage = error == nil ? "蓝牙已断开" : "蓝牙断开：\(error!.localizedDescription)"
        connectedDevice = nil
        writableCharacteristic = nil
        pendingGyroCommand = nil
        writeInFlight = false
    }
}

extension SensorBallBLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            statusMessage = "发现服务失败：\(error.localizedDescription)"
            return
        }
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            statusMessage = "发现通道失败：\(error.localizedDescription)"
            return
        }
        service.characteristics?.forEach { configure(characteristic: $0, on: peripheral) }
        if writableCharacteristic != nil {
            statusMessage = "蓝牙已就绪"
            flushPendingGyroCommand()
        } else {
            statusMessage = "已连接，等待可写入计数通道"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            return
        }
        for packet in SensorBallBLEManager.parseTelemetryPackets(characteristic.value) {
            latestTelemetry = packet
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        writeInFlight = false
        if let error {
            statusMessage = "写入计数指令失败：\(error.localizedDescription)"
        }
        flushPendingGyroCommand()
    }
}
