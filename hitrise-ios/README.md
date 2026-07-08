# Vimai HitRise iOS

Native SwiftUI iOS client for the Vimai HitRise standing boxing speed ball.

## Project Identity

- Display name: `智能拳击速度球`
- Chinese subtitle: `立式拳击速度球`
- Bundle ID: `com.zclei.hitrise`
- API base URL: `https://hitrise.86086.cn/hitrise`
- Preferred future domain: `https://api.vimaihitrise.com/hitrise`
- Fallback future domain: `https://api.vimai-hitrise.com/hitrise`

## Implemented MVP

- SwiftUI tab shell for training, BLE device connection, cloud history/leaderboard, and settings.
- CoreBluetooth BLE scan/connect/notify/write flow for `SENBALL#` devices.
- Sensor packet parsing compatible with the Android `D5 5D 03` 11-byte telemetry packet.
- Gyroscope/counting command compatible with Android `C5 5C 04 01/00`.
- Training countdown, hit counting, force stats, calorie/fat estimates, and training report creation.
- `URLSession` client for the existing FastAPI endpoints.
- Local anonymous device profile using `UserDefaults` and SHA-256.
- Bluetooth permission usage text, ATS HTTP exception for the current IP, and a minimal privacy manifest.
- Generated placeholder AppIcon and AccentColor asset catalog for local Archive/TestFlight preparation.

## Before TestFlight

1. Open `VimaiHitRise.xcodeproj` in Xcode on macOS.
2. Select your Apple Developer team for automatic signing.
3. Replace the generated placeholder app icon with production artwork.
4. Test on a real iPhone with the SENBALL BLE device.
5. `HITRISE_API_BASE_URL` in `Resources/Info.plist` is configured for the current HTTPS endpoint.

## App Store Notes

The project now uses the production HTTPS endpoint `https://hitrise.86086.cn/hitrise`, so the early HTTP/IP ATS exception has been removed.
