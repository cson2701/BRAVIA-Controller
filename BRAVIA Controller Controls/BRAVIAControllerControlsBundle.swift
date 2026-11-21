import SwiftUI
import WidgetKit

@main
struct BRAVIAControllerControlsBundle: WidgetBundle {
    var body: some Widget {
        BRAVIAControllerControl()
        BRAVIAPowerControl()
        BRAVIAMuteControl()
        BRAVIAVolumeUpControl()
        BRAVIAVolumeDownControl()
        BRAVIAInputControl()
        BRAVIAUpControl()
        BRAVIASettingsControl()
        BRAVIALeftControl()
        BRAVIAOKControl()
        BRAVIARightControl()
        BRAVIABackControl()
        BRAVIADownControl()
        BRAVIAHomeControl()
        BRAVIAHomeRemoteWidget()
    }
}
