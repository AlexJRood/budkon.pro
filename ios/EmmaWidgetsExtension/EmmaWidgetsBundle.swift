import SwiftUI
import WidgetKit

@main
struct EmmaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOSApplicationExtension 16.2, *) {
            EmmaMeetingLiveActivityWidget()
        }
    }
}