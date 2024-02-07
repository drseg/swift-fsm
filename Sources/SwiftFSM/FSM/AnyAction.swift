import Foundation

public typealias FSMSyncAction = @MainActor () -> Void
public typealias FSMAsyncAction = @MainActor () async -> Void
public typealias FSMSyncActionWithEvent<Event: FSMType> = @MainActor (Event) -> Void
public typealias FSMAsyncActionWithEvent<Event: FSMType> = @MainActor (Event) async -> Void

public struct AnyAction: @unchecked Sendable {
    public enum NullEvent: FSMType { case null }

    private let base: Any

    init(_ action: @escaping FSMSyncAction) {
        base = action
    }

    init(_ action: @escaping FSMAsyncAction) {
        base = action
    }

    init<Event: FSMType>(_ action: @escaping FSMSyncActionWithEvent<Event>) {
        base = action
    }

    init<Event: FSMType>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
        base = action
    }

    @MainActor
    func callAsFunction<Event: FSMType>(_ event: Event = NullEvent.null) throws {
        if let base = base as? FSMSyncAction {
            base()
        } else if let base = base as? FSMSyncActionWithEvent<Event> {
            base(event)
        } else if base is FSMAsyncAction || base is FSMAsyncActionWithEvent<Event> {
            throw "'handleEvent' can only call synchronous actions. Use 'handleEventAsync' instead"
        } else {
            throw "Action that takes an Event argument called without an Event"
        }
    }

    @MainActor
    func callAsFunction<Event: FSMType>(_ event: Event = NullEvent.null) async {
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
