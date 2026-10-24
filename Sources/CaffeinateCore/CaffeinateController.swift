import Combine
import Foundation

public enum SessionDuration: Int, CaseIterable, Sendable {
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200
    case indefinitely = 0

    public var label: String {
        switch self {
        case .thirtyMinutes: "30 min"
        case .oneHour: "1 hour"
        case .twoHours: "2 hours"
        case .indefinitely: "Unlimited"
        }
    }
}

public struct Session: Equatable, Sendable {
    public let startedAt: Date
    public let duration: SessionDuration
    public let processIdentifier: Int32

    public var endsAt: Date? {
        duration == .indefinitely ? nil : startedAt.addingTimeInterval(Double(duration.rawValue))
    }

    public func clock(at date: Date) -> String {
        let seconds = if let endsAt {
            max(0, Int(ceil(endsAt.timeIntervalSince(date))))
        } else {
            max(0, Int(date.timeIntervalSince(startedAt)))
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, remainder)
            : String(format: "%02d:%02d", minutes, remainder)
    }
}

@MainActor
public final class CaffeinateController: ObservableObject {
    @Published public private(set) var session: Session?
    @Published public private(set) var errorMessage: String?

    private let executableURL: URL
    private var process: Process?

    public init(executableURL: URL = URL(fileURLWithPath: "/usr/bin/caffeinate")) {
        self.executableURL = executableURL
    }

    public var isRunning: Bool { session != nil }

    public static func arguments(for duration: SessionDuration, parentPID: Int32) -> [String] {
        // Binding assertions to our PID also releases them if the app crashes.
        var arguments = ["-disu", "-w", String(parentPID)]
        if duration != .indefinitely {
            arguments += ["-t", String(duration.rawValue)]
        }
        return arguments
    }

    public func start(duration: SessionDuration) {
        guard process == nil else { return }
        launch(duration: duration)
    }

    public func changeDuration(to duration: SessionDuration) {
        guard let session, session.duration != duration else { return }
        launch(duration: duration)
    }

    private func launch(duration: SessionDuration) {
        errorMessage = nil

        let child = Process()
        child.executableURL = executableURL
        child.arguments = Self.arguments(for: duration, parentPID: ProcessInfo.processInfo.processIdentifier)
        child.standardInput = FileHandle.nullDevice
        child.standardOutput = FileHandle.nullDevice
        child.standardError = FileHandle.nullDevice
        child.terminationHandler = { [weak self] terminated in
            Task { @MainActor [weak self] in
                guard let self, self.process === terminated else { return }
                self.process = nil
                self.session = nil
                if terminated.terminationStatus != 0 {
                    self.errorMessage = "The keep-awake session ended unexpectedly. Try starting it again."
                }
            }
        }

        do {
            try child.run()
            let previous = process
            process = child
            session = Session(startedAt: .now, duration: duration, processIdentifier: child.processIdentifier)
            // Acquire the new assertions before releasing the old session.
            if let previous, previous.isRunning {
                previous.terminate()
            }
        } catch {
            child.terminationHandler = nil
            errorMessage = "Could not start caffeinate: \(error.localizedDescription)"
        }
    }

    public func stop() {
        let child = process
        process = nil
        session = nil
        errorMessage = nil
        if let child, child.isRunning {
            child.terminate()
        }
    }
}
