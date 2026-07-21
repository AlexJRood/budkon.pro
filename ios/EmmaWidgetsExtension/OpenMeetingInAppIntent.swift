import AppIntents

@available(iOSApplicationExtension 17.0, *)
struct OpenMeetingInAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Meeting"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Event ID")
    var eventId: String

    init() {}

    init(eventId: String) {
        self.eventId = eventId
    }

    func perform() async throws -> some IntentResult {
        MeetingIntentStore.shared.enqueue(
            action: .open,
            eventId: eventId
        )
        return .result()
    }
}