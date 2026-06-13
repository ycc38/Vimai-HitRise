import XCTest
@testable import VimaiHitRise

final class SensorBallBLEManagerTests: XCTestCase {
    func testMatchesSenballNamesUsedByAdvertisements() {
        XCTAssertTrue(SensorBallBLEManager.isBoxingDeviceName("SENBALL#A"))
        XCTAssertTrue(SensorBallBLEManager.isBoxingDeviceName("senball#A-01B"))
        XCTAssertTrue(SensorBallBLEManager.isBoxingDeviceName("SENBALL#1"))
        XCTAssertTrue(SensorBallBLEManager.isBoxingDeviceName("SENBALL"))
        XCTAssertFalse(SensorBallBLEManager.isBoxingDeviceName("Keyboard"))
    }

    func testParsesTelemetryPacketWithProtocolForce() {
        let data = Data([0xD5, 0x5D, 0x03, 0x07, 88, 12, 11, 30, 100, 0, 0])
        let packets = SensorBallBLEManager.parseTelemetryPackets(data)

        XCTAssertEqual(packets.count, 1)
        XCTAssertEqual(packets[0].packetIndex, 7)
        XCTAssertEqual(packets[0].batteryRaw, 88)
        XCTAssertEqual(packets[0].hitCount, 12)
        XCTAssertEqual(packets[0].pressureHitCount, 11)
        XCTAssertEqual(packets[0].forceN, 60)
    }
}
