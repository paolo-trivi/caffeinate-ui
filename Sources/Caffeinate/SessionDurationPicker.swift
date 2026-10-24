import CaffeinateCore
import SwiftUI

struct SessionDurationPicker: View {
    @ObservedObject var controller: CaffeinateController
    @ObservedObject var preferences: Preferences

    var body: some View {
        Picker("Keep awake for", selection: Binding(
            get: { controller.session?.duration ?? preferences.duration },
            set: { duration in
                controller.changeDuration(to: duration)
                preferences.duration = controller.session?.duration ?? duration
            }
        )) {
            ForEach(SessionDuration.allCases, id: \.rawValue) { duration in
                Text(duration.label).tag(duration)
            }
        }
    }
}
