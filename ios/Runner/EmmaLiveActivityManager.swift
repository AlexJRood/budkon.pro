import Foundation
import ActivityKit
import Flutter

@available(iOS 16.2, *)
final class EmmaLiveActivityManager {
    static let shared = EmmaLiveActivityManager()

    private init() {}

    private func complete(_ result: @escaping FlutterResult, _ value: Any?) {
        DispatchQueue.main.async {
            result(value)
        }
    }

    private func findActivity(eventId: String) -> Activity<EmmaMeetingAttributes>? {
        Activity<EmmaMeetingAttributes>.activities.first(where: {
            $0.attributes.eventId == eventId
        })
    }

    private func debugActivitiesSnapshot() {
        let ids = Activity<EmmaMeetingAttributes>.activities.map {
            [
                "activityId": $0.id,
                "eventId": $0.attributes.eventId
            ]
        }
        print("🧩 Live activities snapshot: \(ids)")
    }


    func startMeetingActivity(args: [String: Any], result: @escaping FlutterResult) {
        let authInfo = ActivityAuthorizationInfo()
        print("🔴 LiveActivity areActivitiesEnabled = \(authInfo.areActivitiesEnabled)")
        print("🔴 Existing activities count BEFORE = \(Activity<EmmaMeetingAttributes>.activities.count)")
        print("🔴 Incoming args = \(args)")
        debugActivitiesSnapshot()

        guard authInfo.areActivitiesEnabled else {
            complete(
                result,
                FlutterError(
                    code: "live_activity_disabled",
                    message: "Live Activities are disabled",
                    details: nil
                )
            )
            return
        }

        guard
            let eventId = args["eventId"] as? String,
            let title = args["title"] as? String,
            let subtitle = args["subtitle"] as? String,
            let startIso = args["startIso"] as? String,
            let endIso = args["endIso"] as? String,
            let microphonePermissionGranted = args["microphonePermissionGranted"] as? Bool,
            let locale = args["locale"] as? String,
            let isNoteActive = args["isNoteActive"] as? Bool,
            let transcriptPreview = args["transcriptPreview"] as? String
        else {
            complete(
                result,
                FlutterError(code: "bad_args", message: "Invalid args", details: nil)
            )
            return
        }

        let attributes = EmmaMeetingAttributes(eventId: eventId)
        let state = EmmaMeetingAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            startIso: startIso,
            endIso: endIso,
            microphonePermissionGranted: microphonePermissionGranted,
            locale: locale,
            isNoteActive: isNoteActive,
            transcriptPreview: transcriptPreview
        )

        Task { @MainActor in
            do {
                if let existing = self.findActivity(eventId: eventId) {
                    print("🟡 Updating existing activity for eventId = \(eventId)")
                    await existing.update(
                        ActivityContent(
                            state: state,
                            staleDate: nil
                        )
                    )
                    print("✅ Existing activity updated")
                    print("✅ Activities count AFTER UPDATE = \(Activity<EmmaMeetingAttributes>.activities.count)")
                    self.debugActivitiesSnapshot()
                    self.complete(result, true)
                    return
                }

                let activity = try Activity<EmmaMeetingAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )

                print("✅ Started activity id = \(activity.id), eventId = \(eventId)")
                print("✅ Activities count AFTER START = \(Activity<EmmaMeetingAttributes>.activities.count)")
                self.debugActivitiesSnapshot()
                self.complete(result, true)
            } catch {
                print("❌ live_activity_start_failed = \(error.localizedDescription)")
                self.complete(
                    result,
                    FlutterError(
                        code: "live_activity_start_failed",
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        }
    }

    func updateMeetingActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard
            let eventId = args["eventId"] as? String,
            let title = args["title"] as? String,
            let subtitle = args["subtitle"] as? String,
            let startIso = args["startIso"] as? String,
            let endIso = args["endIso"] as? String,
            let microphonePermissionGranted = args["microphonePermissionGranted"] as? Bool,
            let locale = args["locale"] as? String,
            let isNoteActive = args["isNoteActive"] as? Bool,
            let transcriptPreview = args["transcriptPreview"] as? String
        else {
            complete(
                result,
                FlutterError(code: "bad_args", message: "Invalid args", details: nil)
            )
            return
        }

        guard let activity = findActivity(eventId: eventId) else {
            complete(result, false)
            return
        }

        let state = EmmaMeetingAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            startIso: startIso,
            endIso: endIso,
            microphonePermissionGranted: microphonePermissionGranted,
            locale: locale,
            isNoteActive: isNoteActive,
            transcriptPreview: transcriptPreview
        )

        Task { @MainActor in
            await activity.update(
                ActivityContent(
                    state: state,
                    staleDate: nil
                )
            )
            self.complete(result, true)
        }
    }

    func endMeetingActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard let eventId = args["eventId"] as? String else {
            complete(
                result,
                FlutterError(code: "bad_args", message: "Missing eventId", details: nil)
            )
            return
        }

        guard let activity = findActivity(eventId: eventId) else {
            complete(result, true)
            return
        }

        Task { @MainActor in
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(
                    state: finalState,
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            self.complete(result, true)
        }
    }
}