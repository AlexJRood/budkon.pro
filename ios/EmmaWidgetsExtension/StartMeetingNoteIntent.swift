import AppIntents

@available(iOSApplicationExtension 17.0, *)
struct StartMeetingNoteIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Meeting Note"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event ID")
    var eventId: String

    init() {}

    init(eventId: String) {
        self.eventId = eventId
    }

    func perform() async throws -> some IntentResult {
        MeetingIntentStore.shared.enqueue(
            action: .startNote,
            eventId: eventId
        )
        return .result()
    }
}