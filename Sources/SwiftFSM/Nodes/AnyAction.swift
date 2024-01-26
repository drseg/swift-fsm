import Foundation

public typealias Action = () -> Void
public typealias ActionWithEvent<Event: Hashable> = (Event) -> Void

struct AnyAction {
    struct NullEvent: Hashable { }

    private let base: Any

    init(_ action: @escaping Action) {
        base = action
    }

    init<Event: Hashable>(_ actionWithEvent: @escaping ActionWithEvent<Event>) {
        base = actionWithEvent
    }

    func callAsFunction<Event: Hashable>(_ event: Event = NullEvent()) {
        func noArgAction() {
            (base as! Action)()
        }

        guard !(event is NullEvent) else {
            noArgAction()
            return
        }

        if let action = base as? ActionWithEvent<Event> {
            action(event)
        } else {
            noArgAction()
        }
    }

    func callSafely<Event: Hashable>(_ event: Event = NullEvent()) throws {
        guard base is () -> Void || base is (Event) -> Void else {
            throw "Error: type mismatch in AnyAction"
        }

        self(event)
    }
}
