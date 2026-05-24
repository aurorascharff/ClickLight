import Foundation
import Sparkle

final class UpdateChecker: NSObject, SPUUpdaterDelegate {
    static let shared = UpdateChecker()

    private var updaterController: SPUStandardUpdaterController?

    var isConfigured: Bool {
        guard let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }

        return !publicKey.isEmpty && publicKey != "REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY"
    }

    var updater: SPUUpdater? {
        updaterController?.updater
    }

    private override init() {
        super.init()
        guard isConfigured else { return }

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        guard isConfigured else { return }
        updater?.checkForUpdates()
    }
}
