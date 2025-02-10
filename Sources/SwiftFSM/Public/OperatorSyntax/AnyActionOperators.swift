import Foundation

public extension AnyAction {
    static func & (lhs: Self, rhs: @escaping Action) -> [Self] {
        [lhs, .init(rhs)]
    }

    static func & <Event: FSMHashable>(
        lhs: Self,
        rhs: @escaping ActionWithEvent<Event>
    ) -> [Self] {
        [lhs, .init(rhs)]
    }
}

// MARK: - init with a single FSMAction element, avoiding AnyAction.init
public extension Array<AnyAction> {
    init(_ action: @escaping Action) {
        self.init(arrayLiteral: AnyAction(action))
    }
    
    init<Event: FSMHashable>(_ action: @escaping ActionWithEvent<Event>) {
        self.init(arrayLiteral: AnyAction(action))
    }

    // MARK: combining with single FSMAction elements
    static func & (lhs: Self, rhs: @escaping Action) -> Self {
        lhs + [.init(rhs)]
    }

    static func & <Event: FSMHashable> (
        lhs: Self,
        rhs: @escaping ActionWithEvent<Event>
    ) -> Self {
        lhs + [.init(rhs)]
    }
}

// MARK: - convenience operators, avoiding AnyAction.init
public func & (
    lhs: @escaping Action,
    rhs: @escaping Action
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: FSMHashable> (
    lhs: @escaping Action,
    rhs: @escaping ActionWithEvent<Event>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <Event: FSMHashable>(
    lhs: @escaping ActionWithEvent<Event>,
    rhs: @escaping Action
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

public func & <LHSEvent: FSMHashable, RHSEvent: FSMHashable> (
    lhs: @escaping ActionWithEvent<LHSEvent>,
    rhs: @escaping ActionWithEvent<RHSEvent>
) -> [AnyAction] {
    [.init(lhs), .init(rhs)]
}

// MARK: - Array convenience operators
postfix operator *

public postfix func * (_ value: @escaping Action) -> [AnyAction] {
    Array(value)
}

public postfix func * <Event: FSMHashable>(
    _ value: @escaping ActionWithEvent<Event>
) -> [AnyAction] {
    Array(value)
}
