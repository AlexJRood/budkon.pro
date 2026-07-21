import ActivityKit
import Foundation

struct EmmaMeetingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var startIso: String
        var endIso: String
        var microphonePermissionGranted: Bool
        var locale: String
        var isNoteActive: Bool
        var transcriptPreview: String
    }

    var eventId: String
}