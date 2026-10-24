import AppKit
import CaffeinateCore
import SwiftUI

struct DesktopPanelView: View {
    @ObservedObject var controller: CaffeinateController
    @ObservedObject var preferences: Preferences
    let openMenuBarPanel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 7) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Palette.copper)
                Text("CAFFEINATE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.6)
                Spacer()
                Menu {
                    SessionDurationPicker(controller: controller, preferences: preferences)
                    Divider()
                    Button("Open Caffeinate", action: openMenuBarPanel)
                    Link("trivisonno.dev", destination: AppInfo.websiteURL)
                    Link("View source on GitHub", destination: AppInfo.repositoryURL)
                    Button("Quit Caffeinate") { NSApp.terminate(nil) }
                        .keyboardShortcut("q")
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("Desktop panel options")
                Button { preferences.showsDesktopPanel = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Hide desktop panel")
                .accessibilityLabel("Hide desktop panel")
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(controller.isRunning ? "In the flow." : "Ready when\nyou are.")
                    .font(.system(size: 31, design: .serif))
                    .tracking(-1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 76, alignment: .topLeading)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(controller.isRunning ? Palette.copper : Palette.muted.opacity(0.4))
                            .frame(width: 5, height: 5)
                        Text(controller.isRunning ? "Awake" : "Resting")
                        Spacer()
                        if let session = controller.session {
                            Text(session.clock(at: context.date))
                                .monospacedDigit()
                                .help(session.endsAt == nil ? "Elapsed time" : "Time remaining")
                        } else {
                            Text(preferences.duration.label)
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.muted)
                }
            }

            Button {
                if controller.isRunning {
                    controller.stop()
                } else {
                    controller.start(duration: preferences.duration)
                }
            } label: {
                Label(controller.isRunning ? "Let it rest" : "Keep awake", systemImage: controller.isRunning ? "stop.fill" : "power")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .foregroundStyle(Palette.cream)
                    .background(Palette.copper, in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)

            if let error = controller.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.copper)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(width: 272)
        .foregroundStyle(Palette.ink)
        .background(Palette.cream)
        .preferredColorScheme(.light)
    }
}
