import Foundation

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

    // MARK: combining with single FSMAction elements
    static func & (lhs: Self, rhs: @escaping FSMSyncAction) -> Self {
        lhs + [.init(rhs)]
    }

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

postfix operator *

public postfix func *(_ value: @escaping FSMSyncAction) -> [AnyAction] {
    Array(value)
}

public postfix func *(_ value: @escaping FSMAsyncAction) -> [AnyAction] {
    Array(value)
}

public postfix func *<Event: Hashable>(
    _ value: @escaping FSMSyncActionWithEvent<Event>
) -> [AnyAction] {
    Array(value)
}

public postfix func *<Event: Hashable>(
    _ value: @escaping FSMAsyncActionWithEvent<Event>
) -> [AnyAction] {
    Array(value)
}
