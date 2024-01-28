import Foundation

public typealias FSMAction = @MainActor () -> Void
public typealias FSMAsyncAction = @MainActor () async -> Void
public typealias FSMActionWithEvent<Event: Hashable> = @MainActor (Event) -> Void
public typealias FSMAsyncActionWithEvent<Event: Hashable> = @MainActor (Event) async -> Void

struct AnyAction {
    struct NullEvent: Hashable { }

    private let base: Any

    init(_ action: @escaping FSMAction) {
        base = action
    }

    init(_ action: @escaping FSMAsyncAction) {
        base = action
    }

    init<Event: Hashable>(_ action: @escaping FSMActionWithEvent<Event>) {
        base = action
    }

    init<Event: Hashable>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
        base = action
    }

    @MainActor
    func callAsFunction<Event: Hashable>(_ event: Event = NullEvent()) throws {
        if let base = base as? FSMAction {
            base()
        } else if let base = base as? FSMActionWithEvent<Event> {
            base(event)
        } else if base is FSMAsyncAction || base is FSMAsyncActionWithEvent<Event> {
            throw "Action with async function called synchronously"
        } else {
            throw "Action that requires an event argument called without an event"
        }
    }

    @MainActor
    func callAsFunction<Event: Hashable>(_ event: Event = NullEvent()) async {
        if let base = base as? FSMAction {
            base()
        } else if let base = base as? FSMActionWithEvent<Event> {
            base(event)
        } else if let base = base as? FSMAsyncAction {
            await base()
        } else if let base = base as? FSMAsyncActionWithEvent<Event> {
            await base(event)
        }
    }
}
