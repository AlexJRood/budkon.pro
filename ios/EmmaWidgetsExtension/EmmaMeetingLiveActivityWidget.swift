import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.2, *)
struct EmmaMeetingLiveActivityWidget: Widget {
    private func fallbackURL(action: String, eventId: String) -> URL {
        var components = URLComponents()
        components.scheme = "hously"
        components.host = "meeting"
        components.queryItems = [
            URLQueryItem(name: "action", value: action),
            URLQueryItem(name: "eventId", value: eventId),
        ]
        return components.url!
    }

    private func formattedInterval(startIso: String, endIso: String) -> String {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let basicFormatter = ISO8601DateFormatter()
        basicFormatter.formatOptions = [.withInternetDateTime]

        func parse(_ value: String) -> Date? {
            if let date = fractionalFormatter.date(from: value) {
                return date
            }
            return basicFormatter.date(from: value)
        }

        guard
            let start = parse(startIso),
            let end = parse(endIso)
        else {
            return "\(startIso) → \(endIso)"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        return "\(formatter.string(from: start)) → \(formatter.string(from: end))"
    }

    @ViewBuilder
    private func actionButton(for context: ActivityViewContext<EmmaMeetingAttributes>) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            if context.state.isNoteActive {
                Button(intent: StopMeetingNoteIntent(eventId: context.attributes.eventId)) {
                    Label("Zatrzymaj", systemImage: "stop.fill")
                }
            } else if context.state.microphonePermissionGranted {
                Button(intent: StartMeetingNoteIntent(eventId: context.attributes.eventId)) {
                    Label("Rozpocznij notatkę", systemImage: "mic.fill")
                }
            } else {
                Button(intent: OpenMeetingInAppIntent(eventId: context.attributes.eventId)) {
                    Label("Otwórz aplikację", systemImage: "arrow.up.forward.app")
                }
            }
        } else {
            if context.state.isNoteActive {
                Link(destination: fallbackURL(action: "stopNote", eventId: context.attributes.eventId)) {
                    Label("Zatrzymaj", systemImage: "stop.fill")
                }
            } else if context.state.microphonePermissionGranted {
                Link(destination: fallbackURL(action: "startNote", eventId: context.attributes.eventId)) {
                    Label("Rozpocznij notatkę", systemImage: "mic.fill")
                }
            } else {
                Link(destination: fallbackURL(action: "open", eventId: context.attributes.eventId)) {
                    Label("Otwórz aplikację", systemImage: "arrow.up.forward.app")
                }
            }
        }
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EmmaMeetingAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                Text(context.state.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(context.state.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(
                    formattedInterval(
                        startIso: context.state.startIso,
                        endIso: context.state.endIso
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                if !context.state.transcriptPreview.isEmpty {
                    Text(context.state.transcriptPreview)
                        .font(.caption)
                        .lineLimit(3)
                }

                actionButton(for: context)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Emma")
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isNoteActive ? "waveform" : "calendar")
                }

                DynamicIslandExpandedRegion(.bottom) {
                    actionButton(for: context)
                }
            } compactLeading: {
                Image(systemName: "calendar")
            } compactTrailing: {
                Image(systemName: context.state.isNoteActive ? "mic.fill" : "mic")
            } minimal: {
                Image(systemName: context.state.isNoteActive ? "waveform" : "calendar")
            }
            .widgetURL(fallbackURL(action: "open", eventId: context.attributes.eventId))
        }
    }
}