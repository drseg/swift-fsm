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
    var groupID: UUID
    var isOverride: Bool

    init(groupID: UUID, isOverride: Bool) {
        self.groupID = groupID
        self.isOverride = isOverride
    }
}

struct DefaultIO: Sendable {
    let match: Match,
        event: AnyTraceable?,
        state: AnyTraceable?,
        actions: [AnyAction],
        groupID: UUID,
        isOverride: Bool

    init(
        _ match: Match,
        _ event: AnyTraceable?,
        _ state: AnyTraceable?,
        _ actions: [AnyAction],
        _ groupID: UUID = UUID(),
        _ isOverride: Bool = false
    ) {
        self.match = match
        self.event = event
        self.state = state
        self.actions = actions
        self.groupID = groupID
        self.isOverride = isOverride
    }
}

func makeDefaultIO(
    match: Match = Match(),
    event: AnyTraceable? = nil,
    state: AnyTraceable? = nil,
    actions: [AnyAction] = [],
    groupID: UUID = UUID(),
    isOverride: Bool = false
) -> [DefaultIO] {
    [DefaultIO(match, event, state, actions, groupID, isOverride)]
}

extension String: LocalizedError {
    public var errorDescription: String? { self }
}

infix operator ???: AdditionPrecedence

func ??? <T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
