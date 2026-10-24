import CaffeinateCore
import Foundation
import ServiceManagement

@MainActor
final class Preferences: ObservableObject {
    @Published var showsDesktopPanel: Bool {
        didSet { UserDefaults.standard.set(showsDesktopPanel, forKey: "showsDesktopPanel") }
    }
    @Published var duration: SessionDuration {
        didSet { UserDefaults.standard.set(duration.rawValue, forKey: "sessionDuration") }
    }
    @Published private(set) var loginStatus: SMAppService.Status = .notRegistered
    @Published private(set) var errorMessage: String?

    init() {
        showsDesktopPanel = UserDefaults.standard.bool(forKey: "showsDesktopPanel")
        let saved = UserDefaults.standard.object(forKey: "sessionDuration") as? Int
        duration = saved.flatMap(SessionDuration.init(rawValue:)) ?? .indefinitely
        refreshLoginStatus()
    }

    var launchesAtLogin: Bool {
        loginStatus == .enabled || loginStatus == .requiresApproval
    }

    func refreshLoginStatus() {
        loginStatus = SMAppService.mainApp.status
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "Could not update login settings: \(error.localizedDescription)"
        }
        refreshLoginStatus()
    }
}
