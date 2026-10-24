import AppKit
import SwiftUI

enum AppInfo {
    static let authorURL = URL(string: "https://github.com/paolo-trivi")!
    static let websiteURL = URL(string: "https://trivisonno.dev")!
    static let repositoryURL = URL(string: "https://github.com/paolo-trivi/caffeinate-ui")!

    static var credits: NSAttributedString {
        let text = NSMutableAttributedString(string: "Small cup. Long session.\nMade by ")
        text.append(NSAttributedString(string: "@paolo-trivi", attributes: [.link: authorURL]))
        text.append(NSAttributedString(string: "\n"))
        text.append(NSAttributedString(string: "trivisonno.dev", attributes: [.link: websiteURL]))
        text.append(NSAttributedString(string: "\n"))
        text.append(NSAttributedString(string: "Source on GitHub", attributes: [.link: repositoryURL]))
        return text
    }
}

struct ProjectLinksView: View {
    var body: some View {
        HStack(spacing: 8) {
            Link(destination: AppInfo.websiteURL) {
                Image(systemName: "globe")
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .help("trivisonno.dev · Made by @paolo-trivi")
            .accessibilityLabel("Visit trivisonno.dev, by paolo-trivi")

            Link(destination: AppInfo.repositoryURL) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .help("Source on GitHub · paolo-trivi/caffeinate-ui")
            .accessibilityLabel("Source on GitHub")
        }
        .font(.system(size: 12))
        .foregroundStyle(Palette.muted)
    }
}
