import Darwin
import Foundation
import Testing
@testable import CaffeinateCore

@Suite(.serialized)
@MainActor
struct CaffeinateControllerTests {
    @Test func argumentsPreserveFlagsAndBindToParent() {
        #expect(CaffeinateController.arguments(for: .indefinitely, parentPID: 42) == ["-disu", "-w", "42"])
        #expect(CaffeinateController.arguments(for: .thirtyMinutes, parentPID: 42) == ["-disu", "-w", "42", "-t", "1800"])
    }

    @Test func clockCountsDownAndClampsAtZero() {
        let start = Date(timeIntervalSince1970: 1000)
        let session = Session(startedAt: start, duration: .oneHour, processIdentifier: 1)
        #expect(session.clock(at: start) == "1:00:00")
        #expect(session.clock(at: start.addingTimeInterval(1.2)) == "59:59")
        #expect(session.clock(at: start.addingTimeInterval(3601)) == "00:00")
    }

    @Test func unlimitedSessionCountsUp() {
        let start = Date(timeIntervalSince1970: 1000)
        let session = Session(startedAt: start, duration: .indefinitely, processIdentifier: 1)
        #expect(session.endsAt == nil)
        #expect(session.clock(at: start.addingTimeInterval(3661)) == "1:01:01")
        #expect(session.clock(at: start.addingTimeInterval(-1)) == "00:00")
    }

    @Test func startIsIdempotentAndStopOnlyTerminatesOwnedProcess() async throws {
        let other = Process()
        other.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        other.arguments = ["-i", "-t", "30"]
        try other.run()
        defer {
            if other.isRunning { other.terminate() }
            other.waitUntilExit()
        }

        let controller = CaffeinateController()
        defer { controller.stop() }
        controller.start(duration: .indefinitely)
        let pid = try #require(controller.session?.processIdentifier)
        #expect(kill(pid, 0) == 0)
        controller.start(duration: .oneHour)
        #expect(controller.session?.processIdentifier == pid)
        #expect(controller.session?.duration == .indefinitely)

        controller.stop()
        #expect(!controller.isRunning)
        for _ in 0..<100 where kill(pid, 0) == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(kill(pid, 0) == -1)
        #expect(other.isRunning)
        #expect(controller.errorMessage == nil)
    }

    @Test func launchFailureDoesNotCreateSession() {
        let controller = CaffeinateController(executableURL: URL(fileURLWithPath: "/nonexistent/caffeinate"))
        controller.start(duration: .indefinitely)
        #expect(!controller.isRunning)
        #expect(controller.errorMessage != nil)
        controller.stop()
    }

    @Test func durationChangesReplaceActiveSessionAndUnlimitedRemovesDeadline() async throws {
        let controller = CaffeinateController()
        defer { controller.stop() }
        controller.start(duration: .thirtyMinutes)
        let oldPID = try #require(controller.session?.processIdentifier)

        controller.changeDuration(to: .twoHours)
        let timed = try #require(controller.session)
        #expect(timed.duration == .twoHours)
        #expect(timed.processIdentifier != oldPID)
        #expect(timed.endsAt?.timeIntervalSince(timed.startedAt) == 7200)
        for _ in 0..<100 where kill(oldPID, 0) == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(kill(oldPID, 0) == -1)

        controller.changeDuration(to: .indefinitely)
        let unlimited = try #require(controller.session)
        #expect(unlimited.duration == .indefinitely)
        #expect(unlimited.endsAt == nil)
        #expect(unlimited.processIdentifier != timed.processIdentifier)
        #expect(kill(unlimited.processIdentifier, 0) == 0)

        controller.changeDuration(to: .indefinitely)
        #expect(controller.session == unlimited)
        try await Task.sleep(for: .milliseconds(50))
        #expect(controller.session == unlimited)
    }

    @Test func changingDurationWhileStoppedDoesNotStartSession() {
        let controller = CaffeinateController()
        controller.changeDuration(to: .twoHours)
        #expect(!controller.isRunning)
    }

    @Test func failedDurationChangeKeepsExistingSession() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("caffeinate")
        try FileManager.default.createSymbolicLink(at: executable, withDestinationURL: URL(fileURLWithPath: "/usr/bin/caffeinate"))
        let controller = CaffeinateController(executableURL: executable)
        defer { controller.stop() }
        controller.start(duration: .oneHour)
        let original = try #require(controller.session)
        try FileManager.default.removeItem(at: executable)

        controller.changeDuration(to: .twoHours)
        #expect(controller.session == original)
        #expect(kill(original.processIdentifier, 0) == 0)
        #expect(controller.errorMessage != nil)
    }

    @Test func processExitClearsSession() async throws {
        let controller = CaffeinateController(executableURL: URL(fileURLWithPath: "/usr/bin/true"))
        defer { controller.stop() }
        controller.start(duration: .indefinitely)
        for _ in 0..<100 where controller.isRunning {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!controller.isRunning)
        #expect(controller.errorMessage == nil)
    }

    @Test func oldExitDoesNotClearNewSession() async throws {
        let controller = CaffeinateController()
        defer { controller.stop() }
        controller.start(duration: .oneHour)
        controller.stop()
        controller.start(duration: .twoHours)
        let pid = try #require(controller.session?.processIdentifier)
        try await Task.sleep(for: .milliseconds(100))
        #expect(controller.session?.processIdentifier == pid)
        #expect(controller.session?.duration == .twoHours)
        #expect(controller.errorMessage == nil)
    }

    @Test func unexpectedExitIsReported() async throws {
        let controller = CaffeinateController(executableURL: URL(fileURLWithPath: "/usr/bin/false"))
        defer { controller.stop() }
        controller.start(duration: .indefinitely)
        for _ in 0..<100 where controller.isRunning {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!controller.isRunning)
        #expect(controller.errorMessage != nil)
    }
}
