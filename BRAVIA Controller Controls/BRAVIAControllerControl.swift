import SwiftUI
import WidgetKit

struct BRAVIAControllerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "scrapps.BRAVIA-Controller.open-remote"
        ) {
            ControlWidgetButton(action: OpenRemoteIntent()) {
                Label("BRAVIA Remote", systemImage: "appletvremote.gen3")
            }
        }
        .displayName("BRAVIA Remote")
        .description("Open the BRAVIA remote control.")
    }
}
