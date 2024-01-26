import Foundation

public typealias FSMAction = @MainActor () -> Void
public typealias FSMActionWithEvent<Event: Hashable> = @MainActor (Event) -> Void

struct AnyAction {
    struct NullEvent: Hashable { }

    private let base: Any

    init(_ action: @escaping FSMAction) {
        base = action
    }

    init<Event: Hashable>(_ actionWithEvent: @escaping FSMActionWithEvent<Event>) {
        base = actionWithEvent
    }

    @MainActor
    func callAsFunction<Event: Hashable>(_ event: Event = NullEvent()) {
        func noArgAction() {
            (base as! FSMAction)()
        }

        guard !(event is NullEvent) else {
            noArgAction()
            return
        }

        if let action = base as? FSMActionWithEvent<Event> {
            action(event)
        } else {
            noArgAction()
        }
    }

    @MainActor
    func callSafely<Event: Hashable>(_ event: Event = NullEvent()) throws {
        guard base is FSMAction || base is FSMActionWithEvent<Event> else {
            throw "Error: type mismatch in AnyAction"
        }

        callAsFunction(event)
    }
}
