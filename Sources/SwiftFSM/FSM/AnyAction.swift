import Foundation

public typealias FSMSyncAction = @MainActor () -> Void
public typealias FSMAsyncAction = @MainActor () async -> Void
public typealias FSMSyncActionWithEvent<Event: Hashable> = @MainActor (Event) -> Void
public typealias FSMAsyncActionWithEvent<Event: Hashable> = @MainActor (Event) async -> Void

public struct AnyAction {
    public enum NullEvent: Hashable { case null }

    private let base: Any

    init(_ action: @escaping FSMSyncAction) {
        base = action
    }

    init(_ action: @escaping FSMAsyncAction) {
        base = action
    }

    init<Event: Hashable>(_ action: @escaping FSMSyncActionWithEvent<Event>) {
        base = action
    }

    init<Event: Hashable>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
        base = action
    }

    @MainActor
    func callAsFunction<Event: Hashable>(_ event: Event = NullEvent.null) throws {
        if let base = base as? FSMSyncAction {
            base()
        } else if let base = base as? FSMSyncActionWithEvent<Event> {
            base(event)
        } else if base is FSMAsyncAction || base is FSMAsyncActionWithEvent<Event> {
            throw "Action with async function called synchronously"
        } else {
            throw "Action that requires an event argument called without an event"
        }
    }

    @MainActor
    func callAsFunction<Event: Hashable>(_ event: Event = NullEvent.null) async {
        if let base = base as? FSMSyncAction {
            base()
        } else if let base = base as? FSMSyncActionWithEvent<Event> {
            base(event)
        } else if let base = base as? FSMAsyncAction {
            await base()
        } else if let base = base as? FSMAsyncActionWithEvent<Event> {
            await base(event)
        }
    }
}
