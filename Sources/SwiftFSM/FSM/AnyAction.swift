import Foundation

public typealias FSMSyncAction = @MainActor () -> Void
public typealias FSMAsyncAction = @MainActor () async -> Void
public typealias FSMSyncActionWithEvent<Event: FSMHashable> = @MainActor (Event) -> Void
public typealias FSMAsyncActionWithEvent<Event: FSMHashable> = @MainActor (Event) async -> Void

@MainActor
public struct AnyAction: @unchecked Sendable {
    public enum NullEvent: FSMHashable { case null }

    private let base: Any

    init(_ action: @escaping FSMSyncAction) {
        base = action
    }

    init(_ action: @escaping FSMAsyncAction) {
        base = action
    }

    init<Event: FSMHashable>(_ action: @escaping FSMSyncActionWithEvent<Event>) {
        base = action
    }

    init<Event: FSMHashable>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
        base = action
    }

    func callAsFunction<Event: FSMHashable>(_ event: Event = NullEvent.null) throws {
        switch base {
        case let base as FSMSyncAction:
            base()
        case let base as FSMSyncActionWithEvent<Event>:
            base(event)
        case is FSMAsyncAction, is FSMAsyncActionWithEvent<Event>:
            throw "'handleEvent' can only call synchronous actions. Use 'handleEventAsync' instead"
        default:
            throw "Action that takes an Event argument called without an Event"
        }
    }

    func callAsFunction<Event: FSMHashable>(_ event: Event = NullEvent.null) async {
        switch base {
        case let base as FSMSyncAction:
            base()
        case let base as FSMSyncActionWithEvent<Event>:
            base(event)
        case let base as FSMAsyncAction:
            await base()
        case let base as FSMAsyncActionWithEvent<Event>:
            await base(event)
        default:
            break
        }
    }
}
