import Foundation

protocol NeverEmptyNode: Node {
    var caller: String { get }
    var file: String { get }
    var line: Int { get }
}

extension NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: rest.isEmpty)
    }

    func makeError(if predicate: Bool) -> [Error] {
        predicate ? [EmptyBuilderError(caller: caller, file: file, line: line)] : []
    }
}

class OverridableNode {
    var overrideGroupID: UUID
    var isOverride: Bool

    init(overrideGroupID: UUID, isOverride: Bool) {
        self.overrideGroupID = overrideGroupID
        self.isOverride = isOverride
    }
}

struct DefaultIO: Sendable {
    let descriptor: MatchDescriptor,
        event: AnyTraceable?,
        state: AnyTraceable?,
        actions: [AnyAction],
        overrideGroupID: UUID,
        isOverride: Bool

    init(
        _ match: MatchDescriptor,
        _ event: AnyTraceable?,
        _ state: AnyTraceable?,
        _ actions: [AnyAction],
        _ overrideGroupID: UUID = UUID(),
        _ isOverride: Bool = false
    ) {
        self.descriptor = match
        self.event = event
        self.state = state
        self.actions = actions
        self.overrideGroupID = overrideGroupID
        self.isOverride = isOverride
    }
}

func makeDefaultIO(
    match: MatchDescriptor = MatchDescriptor(),
    event: AnyTraceable? = nil,
    state: AnyTraceable? = nil,
    actions: [AnyAction] = [],
    overrideGroupID: UUID = UUID(),
    isOverride: Bool = false
) -> [DefaultIO] {
    [DefaultIO(match, event, state, actions, overrideGroupID, isOverride)]
}

extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}

infix operator ???: AdditionPrecedence

func ??? <T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
