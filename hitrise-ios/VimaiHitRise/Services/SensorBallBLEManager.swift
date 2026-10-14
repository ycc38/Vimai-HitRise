import Combine
import CoreBluetooth
import Foundation

final class SensorBallBLEManager: NSObject, ObservableObject {
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var devices: [SensorBallDeviceInfo] = []
    @Published private(set) var connectedDevice: SensorBallDeviceInfo?
    @Published private(set) var latestTelemetry: SensorBallTelemetry?
    @Published var status = LocalizedText("蓝牙未初始化", "Bluetooth not initialized", "Bluetooth non initialisé", "บลูทูธยังไม่เริ่มทำงาน")
    @Published private(set) var lastScanDebugText: String = ""

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var writableCharacteristic: CBCharacteristic?
    private var pendingGyroCommand: Bool?
    private var writeInFlight = false
    private var notifiedCharacteristicKeys = Set<String>()
    private let defaults = UserDefaults.standard
    private var isAutoReconnectScan = false
    private var autoReconnectAttempted = false
    private var autoReconnectFailureCount = 0

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    var statusMessage: String {
        status.text
    }

    var isReadyForCounting: Bool {
        connectedDevice != nil && writableCharacteristic != nil && !writeInFlight
    }

    func startScan() {
        guard central.state == .poweredOn else {
            status = LocalizedText("请先开启蓝牙", "Please turn on Bluetooth", "Veuillez activer le Bluetooth", "โปรดเปิดบลูทูธ")
            return
        }
        devices.removeAll()
        peripherals.removeAll()
        lastScanDebugText = ""
        isAutoReconnectScan = false
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        status = LocalizedText("正在扫描附近 BLE 设备...", "Scanning nearby BLE devices...", "Recherche des appareils BLE à proximité...", "กำลังสแกนอุปกรณ์ BLE ใกล้เคียง...")
    }

    func stopScan() {
        central.stopScan()
    }

    func connect(to device: SensorBallDeviceInfo) {
        guard let peripheral = peripherals[device.id] else {
            status = LocalizedText("设备已离线，请重新扫描", "Device is offline. Please scan again.", "Appareil hors ligne. Relancez la recherche.", "อุปกรณ์ออฟไลน์ โปรดสแกนใหม่")
            return
        }
        stopScan()
        writableCharacteristic = nil
        notifiedCharacteristicKeys.removeAll()
        pendingGyroCommand = nil
        writeInFlight = false
        status = LocalizedText("正在连接 \(device.name)...", "Connecting \(device.name)...", "Connexion à \(device.name)...", "กำลังเชื่อมต่อ \(device.name)...")
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
            status = LocalizedText("蓝牙计数通道未就绪", "Bluetooth counting channel not ready", "Canal de comptage Bluetooth non prêt", "ช่องนับบลูทูธยังไม่พร้อม")
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
        status = enabled
            ? LocalizedText("已发送开启计数指令", "Start counting command sent", "Commande de démarrage du comptage envoyée", "ส่งคำสั่งเริ่มนับแล้ว")
            : LocalizedText("已发送关闭计数指令", "Stop counting command sent", "Commande d'arrêt du comptage envoyée", "ส่งคำสั่งหยุดนับแล้ว")
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
        guard let matchedName = names.first(where: SensorBallBLEManager.isBoxingDeviceName) else {
            return
        }
        peripherals[peripheral.identifier] = peripheral
        let item = SensorBallDeviceInfo(
            id: peripheral.identifier,
            name: matchedName,
            rssi: rssi.intValue,
            isLikelySensorBall: true,
            detail: SensorBallBLEManager.discoveryDetail(
                names: names,
                advertisementData: advertisementData,
                isLikelySensorBall: true
            )
        )
        if let index = devices.firstIndex(where: { $0.id == item.id }) {
            devices[index] = item
        } else {
            devices.append(item)
        }
        devices.sort { $0.rssi > $1.rssi }

        if isAutoReconnectScan, matchesSavedDevice(item) {
            isAutoReconnectScan = false
            connect(to: item)
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
        let protocolPowerScore = forceLow | (forceHigh << 8)
        let relativePowerScore = protocolPowerScore > 0 ? protocolPowerScore : max(gyroForceRaw, pressureForceRaw)
        return SensorBallTelemetry(
            packetIndex: Int(bytes[index + 3]),
            batteryRaw: Int(bytes[index + 4]),
            hitCount: Int(bytes[index + 5]),
            pressureHitCount: Int(bytes[index + 6]),
            gyroForceRaw: gyroForceRaw,
            pressureForceRaw: pressureForceRaw,
            forceLow: forceLow,
            forceHigh: forceHigh,
            // Legacy property name retained for cloud payload compatibility. This value is the
            // unitless Relative Power Score reported directly by the hardware.
            forceN: relativePowerScore
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
        guard normalized.range(of: Constants.devicePrefix, options: [.anchored, .caseInsensitive]) != nil,
              normalized.count > Constants.devicePrefix.count,
              let lastScalar = normalized.unicodeScalars.last else {
            return false
        }
        return (65...90).contains(Int(lastScalar.value)) || (97...122).contains(Int(lastScalar.value))
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
        guard let range = text.range(of: Constants.devicePrefix, options: .caseInsensitive) else {
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
        advertisedServiceUUIDObjects(from: advertisementData).map(\.uuidString)
    }

    private static func advertisedServiceUUIDObjects(from advertisementData: [String: Any]) -> [CBUUID] {
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
        return uuids
    }

    private func reconnectLastDevice() {
        guard !autoReconnectAttempted,
              connectedDevice == nil,
              let identifierText = defaults.string(forKey: Constants.lastDeviceIdentifierKey),
              let identifier = UUID(uuidString: identifierText) else {
            return
        }
        autoReconnectAttempted = true
        if let peripheral = central.retrievePeripherals(withIdentifiers: [identifier]).first {
            let name = defaults.string(forKey: Constants.lastDeviceNameKey) ?? peripheral.name ?? Constants.devicePrefix
            guard SensorBallBLEManager.isBoxingDeviceName(name) else {
                startAutoReconnectScan()
                return
            }
            peripherals[identifier] = peripheral
            let item = SensorBallDeviceInfo(id: identifier, name: name, rssi: 0)
            devices = [item]
            connect(to: item)
        } else {
            startAutoReconnectScan()
        }
    }

    private func startAutoReconnectScan() {
        guard central.state == .poweredOn,
              autoReconnectFailureCount < Constants.maxAutoReconnectFailures,
              (defaults.string(forKey: Constants.lastDeviceIdentifierKey) != nil ||
                defaults.string(forKey: Constants.lastDeviceNameKey) != nil) else {
            return
        }
        isAutoReconnectScan = true
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        status = LocalizedText("正在查找上次连接的设备...", "Looking for the last connected device...", "Recherche du dernier appareil connecté...", "กำลังค้นหาอุปกรณ์ที่เชื่อมต่อล่าสุด...")
    }

    private func matchesSavedDevice(_ device: SensorBallDeviceInfo) -> Bool {
        if defaults.string(forKey: Constants.lastDeviceIdentifierKey) == device.id.uuidString {
            return true
        }
        guard let savedName = defaults.string(forKey: Constants.lastDeviceNameKey) else { return false }
        return savedName.compare(device.name, options: .caseInsensitive) == .orderedSame
    }

    private func rememberConnectedDevice(_ device: SensorBallDeviceInfo) {
        defaults.set(device.id.uuidString, forKey: Constants.lastDeviceIdentifierKey)
        defaults.set(device.name, forKey: Constants.lastDeviceNameKey)
    }

    private enum Constants {
        static let devicePrefix = "SENBALL#"
        static let telemetryPacketSize = 11
        static let lastDeviceIdentifierKey = "hitrise.bluetooth.last.identifier"
        static let lastDeviceNameKey = "hitrise.bluetooth.last.name"
        static let maxAutoReconnectFailures = 2
    }
}

extension SensorBallBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        switch central.state {
        case .poweredOn:
            status = LocalizedText("蓝牙已开启", "Bluetooth is on", "Bluetooth activé", "บลูทูธเปิดอยู่")
            reconnectLastDevice()
        case .poweredOff:
            status = LocalizedText("蓝牙已关闭", "Bluetooth is off", "Bluetooth désactivé", "บลูทูธปิดอยู่")
        case .unauthorized:
            status = LocalizedText("蓝牙权限未授权", "Bluetooth permission not granted", "Autorisation Bluetooth refusée", "ยังไม่ได้รับสิทธิ์บลูทูธ")
        case .unsupported:
            status = LocalizedText("当前设备不支持 BLE", "This device does not support BLE", "Cet appareil ne prend pas en charge le BLE", "อุปกรณ์นี้ไม่รองรับ BLE")
        default:
            status = LocalizedText("蓝牙状态初始化中", "Initializing Bluetooth...", "Initialisation du Bluetooth...", "กำลังเริ่มบลูทูธ...")
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let names = SensorBallBLEManager.nameCandidates(from: advertisementData, peripheralName: peripheral.name)
        let name = names.first ?? "N/A"
        let serviceText = SensorBallBLEManager
            .advertisedServiceUUIDs(from: advertisementData)
            .joined(separator: ",")
        lastScanDebugText = "最近广播：\(name)，服务：\(serviceText.isEmpty ? "N/A" : serviceText)，RSSI \(RSSI.intValue)"
        addOrUpdate(peripheral: peripheral, rssi: RSSI, advertisementData: advertisementData)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        connectedDevice = devices.first(where: { $0.id == peripheral.identifier })
            ?? SensorBallDeviceInfo(id: peripheral.identifier, name: peripheral.name ?? "SENBALL", rssi: 0)
        if let connectedDevice, SensorBallBLEManager.isBoxingDeviceName(connectedDevice.name) {
            rememberConnectedDevice(connectedDevice)
        }
        isAutoReconnectScan = false
        autoReconnectFailureCount = 0
        status = LocalizedText("已连接，正在发现服务...", "Connected. Discovering services...", "Connecté. Recherche des services...", "เชื่อมต่อแล้ว กำลังค้นหาบริการ...")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let reason = error?.localizedDescription
        status = LocalizedText(
            "连接失败：\(reason ?? "未知错误")",
            "Connection failed: \(reason ?? "Unknown error")",
            "Échec de la connexion : \(reason ?? "Erreur inconnue")",
            "เชื่อมต่อไม่สำเร็จ: \(reason ?? "ข้อผิดพลาดที่ไม่ทราบสาเหตุ")"
        )
        connectedDevice = nil
        autoReconnectFailureCount += 1
        startAutoReconnectScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error {
            let reason = error.localizedDescription
            status = LocalizedText("蓝牙断开：\(reason)", "Bluetooth disconnected: \(reason)", "Bluetooth déconnecté : \(reason)", "บลูทูธตัดการเชื่อมต่อ: \(reason)")
        } else {
            status = LocalizedText("蓝牙已断开", "Bluetooth disconnected", "Bluetooth déconnecté", "บลูทูธตัดการเชื่อมต่อแล้ว")
        }
        connectedDevice = nil
        writableCharacteristic = nil
        pendingGyroCommand = nil
        writeInFlight = false
    }
}

extension SensorBallBLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            let reason = error.localizedDescription
            status = LocalizedText("发现服务失败：\(reason)", "Service discovery failed: \(reason)", "Échec de la recherche des services : \(reason)", "ค้นหาบริการไม่สำเร็จ: \(reason)")
            return
        }
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            let reason = error.localizedDescription
            status = LocalizedText("发现通道失败：\(reason)", "Characteristic discovery failed: \(reason)", "Échec de la recherche des canaux : \(reason)", "ค้นหาช่องสัญญาณไม่สำเร็จ: \(reason)")
            return
        }
        service.characteristics?.forEach { configure(characteristic: $0, on: peripheral) }
        if writableCharacteristic != nil {
            status = LocalizedText("蓝牙已就绪", "Bluetooth ready", "Bluetooth prêt", "บลูทูธพร้อมแล้ว")
            flushPendingGyroCommand()
        } else {
            status = LocalizedText("已连接，等待可写入计数通道", "Connected. Waiting for a writable counting channel.", "Connecté. En attente d'un canal de comptage inscriptible.", "เชื่อมต่อแล้ว กำลังรอช่องนับที่เขียนได้")
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
            let reason = error.localizedDescription
            status = LocalizedText("写入计数指令失败：\(reason)", "Failed to send counting command: \(reason)", "Échec de l'envoi de la commande de comptage : \(reason)", "ส่งคำสั่งนับไม่สำเร็จ: \(reason)")
        }
        flushPendingGyroCommand()
    }
}
