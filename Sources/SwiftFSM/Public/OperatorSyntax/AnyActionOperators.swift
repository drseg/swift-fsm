import Foundation

public extension AnyAction {
    static func & (lhs: Self, rhs: @escaping FSMAction) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & <Event: FSMHashable>(
        lhs: Self,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> [Self] {
        [lhs, .init(rhs)]
    }
}

// MARK: - init with a single FSMAction element, avoiding AnyAction.init
public extension Array<AnyAction> {
    init(_ action: @escaping FSMAction) {
        self.init(arrayLiteral: AnyAction(action))
    }
    
    init<Event: FSMHashable>(_ action: @escaping FSMActionWithEvent<Event>) {
        self.init(arrayLiteral: AnyAction(action))
    }

    // MARK: combining with single FSMAction elements
    static func & (lhs: Self, rhs: @escaping FSMAction) -> Self {
        lhs + [.init(rhs)]
    }

    static func & <Event: FSMHashable> (
        lhs: Self,
        rhs: @escaping FSMActionWithEvent<Event>
    ) -> Self {
        lhs + [.init(rhs)]
    }
}

// MARK: - convenience operators, avoiding AnyAction.init
public func & (
    lhs: @escaping FSMAction,
    rhs: @escaping FSMAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: FSMHashable> (
    lhs: @escaping FSMAction,
    rhs: @escaping FSMActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: FSMHashable>(
    lhs: @escaping FSMActionWithEvent<Event>,
    rhs: @escaping FSMAction
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <LHSEvent: FSMHashable, RHSEvent: FSMHashable> (
    lhs: @escaping FSMActionWithEvent<LHSEvent>,
    rhs: @escaping FSMActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

// MARK: - Array convenience operators
postfix operator *

public postfix func * (_ value: @escaping FSMAction) -> [AnyAction] {
    Array(value)
}

public postfix func * <Event: FSMHashable>(
    _ value: @escaping FSMActionWithEvent<Event>
) -> [AnyAction] {
    Array(value)
}
