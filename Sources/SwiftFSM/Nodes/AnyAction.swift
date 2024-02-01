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

public extension AnyAction {
    static func & (lhs: Self, rhs: @escaping FSMSyncAction) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & (lhs: Self, rhs: @escaping FSMAsyncAction) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & <Event: Hashable>(
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & <Event: Hashable>(
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> [Self] {
        [lhs, .init(rhs)]
    }
}

public extension Array<AnyAction> {
    // MARK: init with a single FSMAction element, avoiding AnyAction.init
    init(_ action: @escaping FSMSyncAction) {
        self.init(arrayLiteral: AnyAction(action))
    }

    init(_ action: @escaping FSMAsyncAction) {
        self.init(arrayLiteral: AnyAction(action))
    }

    init<Event: Hashable>(_ action: @escaping FSMSyncActionWithEvent<Event>) {
        self.init(arrayLiteral: AnyAction(action))
    }

    init<Event: Hashable>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
        self.init(arrayLiteral: AnyAction(action))
    }

    static func & (lhs: Self, rhs: @escaping FSMSyncAction) -> Self {
        lhs + [.init(rhs)]
    }

    // MARK: combining with single FSMAction elements
    static func & (lhs: Self, rhs: @escaping FSMAsyncAction) -> Self {
        lhs + [.init(rhs)]
    }

    static func & <Event: Hashable> (
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Self {
        lhs + [.init(rhs)]
    }

    static func & <Event: Hashable> (
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> Self {
        lhs + [.init(rhs)]
    }
}

// MARK: convenience operators, avoiding AnyAction.init
public func & (
    lhs: @escaping FSMSyncAction,
    rhs: @escaping FSMSyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable> (
    lhs: @escaping FSMSyncAction,
    rhs: @escaping FSMSyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable> (
    lhs: @escaping FSMSyncAction,
    rhs: @escaping FSMAsyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable>(
    lhs: @escaping FSMSyncActionWithEvent<Event>,
    rhs: @escaping FSMSyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable>(
    lhs: @escaping FSMSyncActionWithEvent<Event>,
    rhs: @escaping FSMAsyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <LHSEvent: Hashable, RHSEvent: Hashable> (
    lhs: @escaping FSMSyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMSyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <LHSEvent: Hashable, RHSEvent: Hashable> (
    lhs: @escaping FSMSyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMAsyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & (
    lhs: @escaping FSMAsyncAction,
    rhs: @escaping FSMAsyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable> (
    lhs: @escaping FSMAsyncAction,
    rhs: @escaping FSMSyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable> (
    lhs: @escaping FSMAsyncAction,
    rhs: @escaping FSMAsyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable>(
    lhs: @escaping FSMAsyncActionWithEvent<Event>,
    rhs: @escaping FSMSyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: Hashable>(
    lhs: @escaping FSMAsyncActionWithEvent<Event>,
    rhs: @escaping FSMAsyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <LHSEvent: Hashable, RHSEvent: Hashable> (
    lhs: @escaping FSMAsyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMSyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <LHSEvent: Hashable, RHSEvent: Hashable> (
    lhs: @escaping FSMAsyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMAsyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}
