import Foundation

public typealias FSMSyncAction = @MainActor () -> Void
public typealias FSMAsyncAction = @MainActor () async -> Void
public typealias FSMSyncActionWithEvent<Event: Hashable> = @MainActor (Event) -> Void
public typealias FSMAsyncActionWithEvent<Event: Hashable> = @MainActor (Event) async -> Void

public struct AnyAction {
    public static func + (lhs: Self, rhs: @escaping FSMSyncAction) -> [Self] {
        [lhs, AnyAction(rhs)]
    }

    public static func + (lhs: Self, rhs: @escaping FSMAsyncAction) -> [Self] {
        [lhs, AnyAction(rhs)]
    }

    public static func + <Event: Hashable>(
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> [Self] {
        [lhs, AnyAction(rhs)]
    }

    public static func + <Event: Hashable>(
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> [Self] {
        [lhs, AnyAction(rhs)]
    }

    public enum NullEvent: Hashable { case null }

    private let base: Any

    public static func nullSync(_: NullEvent) { }
    public static func nullAsync(_: NullEvent) async { }

    public init(_ action: @escaping FSMSyncAction) {
        base = action
    }

    public init(_ action: @escaping FSMAsyncAction) {
        base = action
    }

    public init<Event: Hashable>(_ action: @escaping FSMSyncActionWithEvent<Event>) {
        base = action
    }

    public init<Event: Hashable>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
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

public extension Array<AnyAction> {
    static func + (lhs: Self, rhs: @escaping FSMSyncAction) -> Self {
        lhs + [AnyAction(rhs)]
    }

    static func + (lhs: Self, rhs: @escaping FSMAsyncAction) -> Self {
        lhs + [AnyAction(rhs)]
    }

    static func + <Event: Hashable> (
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Self {
        lhs + [AnyAction(rhs)]
    }

    static func + <Event: Hashable> (
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> Self {
        lhs + [AnyAction(rhs)]
    }
}
