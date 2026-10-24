import AppKit
import CaffeinateCore
import ServiceManagement
import SwiftUI

enum Palette {
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let ink = Color(red: 0.20, green: 0.19, blue: 0.16)
    static let muted = Color(red: 0.49, green: 0.46, blue: 0.41)
    static let copper = Color(red: 0.70, green: 0.29, blue: 0.17)
    static let line = Color(red: 0.86, green: 0.83, blue: 0.77)
    static let green = Color(red: 0.72, green: 0.83, blue: 0.53)
}

struct CaffeinateView: View {
    @ObservedObject var controller: CaffeinateController
    @ObservedObject var preferences: Preferences

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 25)

            VStack(alignment: .leading, spacing: 9) {
                Text(controller.isRunning ? "Keep the\nideas coming." : "Your Mac,\nwide awake.")
                    .font(.system(size: 43, weight: .regular, design: .serif))
                    .tracking(-1.8)
                    .lineSpacing(-5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(controller.isRunning ? "You make things. We keep the lights on." : "For long builds and one more good idea.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
            }

            CupIllustration(isRunning: controller.isRunning)
                .frame(height: 150)
                .padding(.vertical, 8)
                .accessibilityHidden(true)

            sessionCard
                .padding(.bottom, 22)

            HStack {
                Text("KEEP AWAKE FOR")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.6)
                Spacer()
                if controller.isRunning {
                    Text("From now")
                        .font(.system(size: 10))
                }
            }
            .foregroundStyle(Palette.muted)
            .padding(.bottom, 9)

            SessionDurationPicker(controller: controller, preferences: preferences)
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.large)
            .help("Changing duration restarts an active session's timer from now.")
            .padding(.bottom, 14)

            Button {
                if controller.isRunning {
                    controller.stop()
                } else {
                    controller.start(duration: preferences.duration)
                }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: controller.isRunning ? "stop.fill" : "power")
                        .font(.system(size: 12, weight: .semibold))
                    Text(controller.isRunning ? "Let it rest" : "Keep awake")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("⌘ K")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .opacity(0.65)
                }
                .padding(.horizontal, 18)
                .frame(height: 50)
                .foregroundStyle(Palette.cream)
                .background(Palette.copper, in: RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)
            .help("Toggle keep-awake while this panel is open (Command-K)")

            if let error = controller.errorMessage ?? preferences.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.copper)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .accessibilityLabel("Error: \(error)")
            }

            if preferences.loginStatus == .requiresApproval {
                Button("Allow in System Settings") {
                    SMAppService.openSystemSettingsLoginItems()
                }
                .font(.system(size: 11))
                .padding(.top, 10)
            }

            footer
                .padding(.top, 19)
        }
        .padding(24)
        .frame(width: 356)
        .foregroundStyle(Palette.ink)
        .background(Palette.cream)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 14))
                .foregroundStyle(Palette.copper)
            Text("CAFFEINATE")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
            Spacer()
            Text("A LITTLE MAC UTILITY")
                .font(.system(size: 7, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Palette.muted)
        }
    }

    private var sessionCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(Palette.cream.opacity(0.15), lineWidth: 2)
                    if let session = controller.session, let end = session.endsAt {
                        let progress = max(0, min(1, end.timeIntervalSince(context.date) / Double(session.duration.rawValue)))
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Palette.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    Image(systemName: controller.isRunning ? "sun.max" : "moon")
                        .font(.system(size: 15))
                        .foregroundStyle(controller.isRunning ? Palette.green : Palette.cream.opacity(0.65))
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(controller.isRunning ? Palette.green : Palette.cream.opacity(0.35))
                            .frame(width: 5, height: 5)
                        Text(controller.isRunning ? "Wide awake" : "Taking it easy")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(sessionDetail)
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.cream.opacity(0.55))
                }
                Spacer(minLength: 4)
                if let session = controller.session {
                    Text(session.clock(at: context.date))
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .accessibilityLabel("\(session.clock(at: context.date)) \(session.endsAt == nil ? "elapsed" : "remaining")")
                } else {
                    Text("OFF")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(Palette.cream.opacity(0.4))
                }
            }
            .padding(15)
            .foregroundStyle(Palette.cream)
            .background(Palette.ink, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var sessionDetail: String {
        guard let session = controller.session else { return "Your Mac can sleep as usual." }
        if let end = session.endsAt {
            return "Until \(end.formatted(date: .omitted, time: .shortened)) · remaining"
        }
        return "Until you say so · elapsed"
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Rectangle().fill(Palette.line).frame(height: 1)
            HStack {
                Toggle("Launch at login", isOn: Binding(
                    get: { preferences.launchesAtLogin },
                    set: { preferences.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.system(size: 11))
                .tint(Palette.copper)
                .fixedSize()
                Spacer()
                ProjectLinksView()
                Menu {
                    Button(preferences.showsDesktopPanel ? "Hide desktop panel" : "Show desktop panel") {
                        preferences.showsDesktopPanel.toggle()
                    }
                    Divider()
                    Link("View source on GitHub", destination: AppInfo.repositoryURL)
                    Button("About Caffeinate") {
                        NSApp.orderFrontStandardAboutPanel(options: [
                            .applicationName: "Caffeinate",
                            .credits: AppInfo.credits,
                        ])
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    Divider()
                    Button("Quit Caffeinate", role: .destructive) { NSApp.terminate(nil) }
                        .keyboardShortcut("q")
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 25, height: 20)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("More options")
            }
        }
    }
}

private struct CupIllustration: View {
    let isRunning: Bool

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 260, size.height / 150)
            context.translateBy(x: (size.width - 260 * scale) / 2, y: 0)
            context.scaleBy(x: scale, y: scale)

            context.fill(Path(ellipseIn: CGRect(x: 43, y: 128, width: 174, height: 12)), with: .color(Palette.ink.opacity(0.06)))
            context.stroke(Path(ellipseIn: CGRect(x: 48, y: 120, width: 164, height: 14)), with: .color(Palette.copper.opacity(0.35)), lineWidth: 1.5)

            var handle = Path()
            handle.move(to: CGPoint(x: 173, y: 64))
            handle.addCurve(to: CGPoint(x: 174, y: 102), control1: CGPoint(x: 220, y: 53), control2: CGPoint(x: 220, y: 108))
            context.stroke(handle, with: .color(Palette.copper), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            var cup = Path()
            cup.move(to: CGPoint(x: 78, y: 58))
            cup.addLine(to: CGPoint(x: 181, y: 58))
            cup.addCurve(to: CGPoint(x: 160, y: 121), control1: CGPoint(x: 180, y: 103), control2: CGPoint(x: 176, y: 121))
            cup.addQuadCurve(to: CGPoint(x: 99, y: 121), control: CGPoint(x: 130, y: 130))
            cup.addCurve(to: CGPoint(x: 78, y: 58), control1: CGPoint(x: 83, y: 121), control2: CGPoint(x: 79, y: 100))
            cup.closeSubpath()
            context.fill(cup, with: .linearGradient(
                Gradient(colors: [Palette.copper, Color(red: 0.57, green: 0.23, blue: 0.14)]),
                startPoint: CGPoint(x: 80, y: 60), endPoint: CGPoint(x: 180, y: 130)
            ))
            context.fill(Path(ellipseIn: CGRect(x: 78, y: 52, width: 103, height: 15)), with: .color(Color(red: 0.83, green: 0.50, blue: 0.35)))
            context.fill(Path(ellipseIn: CGRect(x: 84, y: 56, width: 91, height: 8)), with: .color(Palette.ink))

            var highlight = Path()
            highlight.move(to: CGPoint(x: 88, y: 74))
            highlight.addQuadCurve(to: CGPoint(x: 101, y: 111), control: CGPoint(x: 89, y: 103))
            context.stroke(highlight, with: .color(.white.opacity(0.15)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            for index in 0..<3 {
                let x = CGFloat(110 + index * 19)
                var steam = Path()
                steam.move(to: CGPoint(x: x, y: 41))
                steam.addCurve(to: CGPoint(x: x, y: 9), control1: CGPoint(x: x + 13, y: 29), control2: CGPoint(x: x - 11, y: 23))
                context.stroke(steam, with: .color(Palette.copper.opacity(isRunning ? 0.5 : 0.16)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }

            for (x, y, length) in [(53.0, 65.0, 10.0), (215.0, 36.0, 7.0)] {
                var ray = Path()
                ray.move(to: CGPoint(x: x - length / 2, y: y))
                ray.addLine(to: CGPoint(x: x + length / 2, y: y))
                ray.move(to: CGPoint(x: x, y: y - length / 2))
                ray.addLine(to: CGPoint(x: x, y: y + length / 2))
                context.stroke(ray, with: .color(Palette.copper.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
        }
    }
}
