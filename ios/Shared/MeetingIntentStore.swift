import Foundation

enum MeetingIntentAction: String, Codable {
    case startNote
    case stopNote
    case open
}

struct MeetingIntentCommand: Codable {
    let action: MeetingIntentAction
    let eventId: String
    let receivedAt: TimeInterval
}

final class MeetingIntentStore {
    static let shared = MeetingIntentStore()

    private let suiteName = "group.pro.hously.shared"
    private let commandKey = "meeting_intent_command"

    private init() {}

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func enqueue(action: MeetingIntentAction, eventId: String) {
        guard let defaults else {
            print("❌ MeetingIntentStore: App Group defaults unavailable")
            return
        }

        let command = MeetingIntentCommand(
            action: action,
            eventId: eventId,
            receivedAt: Date().timeIntervalSince1970
        )

        do {
            let data = try JSONEncoder().encode(command)
            defaults.set(data, forKey: commandKey)
            defaults.synchronize()
            print("✅ MeetingIntentStore enqueue action=\(action.rawValue), eventId=\(eventId)")
        } catch {
            print("❌ MeetingIntentStore enqueue failed: \(error)")
        }
    }

    func consumeDictionary() -> [String: Any]? {
        guard let defaults else {
            print("❌ MeetingIntentStore: App Group defaults unavailable on consume")
            return nil
        }

        guard let data = defaults.data(forKey: commandKey) else {
            return nil
        }

        defaults.removeObject(forKey: commandKey)
        defaults.synchronize()

        do {
            let command = try JSONDecoder().decode(MeetingIntentCommand.self, from: data)
            let payload: [String: Any] = [
                "action": command.action.rawValue,
                "eventId": command.eventId,
                "receivedAt": command.receivedAt,
            ]
            print("📤 MeetingIntentStore consume payload: \(payload)")
            return payload
        } catch {
            print("❌ MeetingIntentStore consume failed: \(error)")
            return nil
        }
    }
}