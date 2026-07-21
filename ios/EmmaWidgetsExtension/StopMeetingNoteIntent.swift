import AppIntents

@available(iOSApplicationExtension 17.0, *)
struct StopMeetingNoteIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Meeting Note"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event ID")
    var eventId: String

    init() {}

    init(eventId: String) {
        self.eventId = eventId
    }

    func perform() async throws -> some IntentResult {
        MeetingIntentStore.shared.enqueue(
            action: .stopNote,
            eventId: eventId
        )
        return .result()
    }
}