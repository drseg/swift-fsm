import Foundation

public typealias FSMSyncAction = @isolated(any) () -> Void
public typealias FSMAsyncAction = @isolated(any) () async -> Void
public typealias FSMSyncActionWithEvent<Event: FSMHashable> = @isolated(any) (Event) -> Void
public typealias FSMAsyncActionWithEvent<Event: FSMHashable> = @isolated(any) (Event) async -> Void

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

    func callAsFunction<Event: FSMHashable>(_ event: Event = NullEvent.null) async {
        switch base {
        case let base as FSMSyncAction:
            await base()
        case let base as FSMSyncActionWithEvent<Event>:
            await base(event)
        case let base as FSMAsyncAction:
            await base()
        case let base as FSMAsyncActionWithEvent<Event>:
            await base(event)
        default:
            break
        }
    }
}
