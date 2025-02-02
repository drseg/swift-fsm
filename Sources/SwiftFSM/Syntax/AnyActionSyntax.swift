import Foundation

public extension AnyAction {
    static func & (lhs: Self, rhs: @escaping FSMSyncAction) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & (lhs: Self, rhs: @escaping FSMAsyncAction) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & <Event: FSMHashable>(
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & <Event: FSMHashable>(
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> [Self] {
        [lhs, .init(rhs)]
    }
}

// MARK: - init with a single FSMAction element, avoiding AnyAction.init
@MainActor
public extension Array<AnyAction> {
    init(_ action: @escaping FSMSyncAction) {
        self.init(arrayLiteral: AnyAction(action))
    }

    init(_ action: @escaping FSMAsyncAction) {
        self.init(arrayLiteral: AnyAction(action))
    }

    init<Event: FSMHashable>(_ action: @escaping FSMSyncActionWithEvent<Event>) {
        self.init(arrayLiteral: AnyAction(action))
    }

    init<Event: FSMHashable>(_ action: @escaping FSMAsyncActionWithEvent<Event>) {
        self.init(arrayLiteral: AnyAction(action))
    }

    // MARK: combining with single FSMAction elements
    static func & (lhs: Self, rhs: @escaping FSMSyncAction) -> Self {
        lhs + [.init(rhs)]
    }

    static func & (lhs: Self, rhs: @escaping FSMAsyncAction) -> Self {
        lhs + [.init(rhs)]
    }

    static func & <Event: FSMHashable> (
        lhs: Self,
        rhs: @escaping FSMSyncActionWithEvent<Event>
    ) -> Self {
        lhs + [.init(rhs)]
    }

    static func & <Event: FSMHashable> (
        lhs: Self,
        rhs: @escaping FSMAsyncActionWithEvent<Event>
    ) -> Self {
        lhs + [.init(rhs)]
    }
}

// MARK: - convenience operators, avoiding AnyAction.init
@MainActor
public func & (
    lhs: @escaping FSMSyncAction,
    rhs: @escaping FSMSyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable> (
    lhs: @escaping FSMSyncAction,
    rhs: @escaping FSMSyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable> (
    lhs: @escaping FSMSyncAction,
    rhs: @escaping FSMAsyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable>(
    lhs: @escaping FSMSyncActionWithEvent<Event>,
    rhs: @escaping FSMSyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable>(
    lhs: @escaping FSMSyncActionWithEvent<Event>,
    rhs: @escaping FSMAsyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <LHSEvent: FSMHashable, RHSEvent: FSMHashable> (
    lhs: @escaping FSMSyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMSyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <LHSEvent: FSMHashable, RHSEvent: FSMHashable> (
    lhs: @escaping FSMSyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMAsyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & (
    lhs: @escaping FSMAsyncAction,
    rhs: @escaping FSMAsyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable> (
    lhs: @escaping FSMAsyncAction,
    rhs: @escaping FSMSyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable> (
    lhs: @escaping FSMAsyncAction,
    rhs: @escaping FSMAsyncActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable>(
    lhs: @escaping FSMAsyncActionWithEvent<Event>,
    rhs: @escaping FSMSyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <Event: FSMHashable>(
    lhs: @escaping FSMAsyncActionWithEvent<Event>,
    rhs: @escaping FSMAsyncAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <LHSEvent: FSMHashable, RHSEvent: FSMHashable> (
    lhs: @escaping FSMAsyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMSyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

@MainActor
public func & <LHSEvent: FSMHashable, RHSEvent: FSMHashable> (
    lhs: @escaping FSMAsyncActionWithEvent<LHSEvent>,
    rhs: @escaping FSMAsyncActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

// MARK: - Array convenience operators
postfix operator *

@MainActor
public postfix func * (_ value: @escaping FSMSyncAction) -> [AnyAction] {
    Array(value)
}

@MainActor
public postfix func * (_ value: @escaping FSMAsyncAction) -> [AnyAction] {
    Array(value)
}

@MainActor
public postfix func * <Event: FSMHashable>(
    _ value: @escaping FSMSyncActionWithEvent<Event>
) -> [AnyAction] {
    Array(value)
}

@MainActor
public postfix func * <Event: FSMHashable>(
    _ value: @escaping FSMAsyncActionWithEvent<Event>
) -> [AnyAction] {
    Array(value)
}
