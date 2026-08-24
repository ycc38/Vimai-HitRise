import Foundation

enum LegalCopy {
    static let privacySummary = """
    Vimai HitRise 会在本机生成匿名标识。只有在你明确同意开启云端训练记录与排行榜后，App 才会使用该标识上传训练记录并同步排行榜和统计信息。

    App 会请求蓝牙权限以连接立式拳击速度球，并接收拳数、力度、电量等训练数据。App 不接入通讯录、定位、相机、麦克风或 HealthKit。

    你可以拒绝开启云端功能并继续本地训练，也可以随时在设置中更改选择。
    """

    static let userAgreementSummary = """
    Vimai HitRise 是立式拳击速度球配套训练 App。训练结果仅供运动参考，不构成医疗建议。

    使用时请确保设备安装稳固、周围空间安全，并根据自身身体状态调整训练强度。

    云端排行榜和历史记录依赖网络连接。网络不可用时，部分同步能力可能暂时不可用。
    """
}
