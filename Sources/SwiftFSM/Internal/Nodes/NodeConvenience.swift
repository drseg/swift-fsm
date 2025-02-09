import Foundation

protocol NeverEmptyNode: SyntaxNode {
    var caller: String { get }
    var file: String { get }
    var line: Int { get }
}

extension NeverEmptyNode {
    func findErrors() -> [Error] {
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

struct RawSyntaxDTO: Sendable {
    let descriptor: MatchDescriptorChain,
        event: AnyTraceable?,
        state: AnyTraceable?,
        actions: [AnyAction],
        overrideGroupID: UUID,
        isOverride: Bool

    init(
        _ descriptor: MatchDescriptorChain,
        _ event: AnyTraceable?,
        _ state: AnyTraceable?,
        _ actions: [AnyAction],
        _ overrideGroupID: UUID = UUID(),
        _ isOverride: Bool = false
    ) {
        self.descriptor = descriptor
        self.event = event
        self.state = state
        self.actions = actions
        self.overrideGroupID = overrideGroupID
        self.isOverride = isOverride
    }
}

func makeDefaultIO(
    match: MatchDescriptorChain = MatchDescriptorChain(),
    event: AnyTraceable? = nil,
    state: AnyTraceable? = nil,
    actions: [AnyAction] = [],
    overrideGroupID: UUID = UUID(),
    isOverride: Bool = false
) -> [RawSyntaxDTO] {
    [RawSyntaxDTO(match, event, state, actions, overrideGroupID, isOverride)]
}

extension SyntaxNode {
    func appending<Other: SyntaxNode>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}

extension Array {
    var nodes: [any SyntaxNode<RawSyntaxDTO>] {
        compactMap { ($0 as? Syntax.CompoundSyntax)?.node }
    }
}

extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}

infix operator ???: AdditionPrecedence

func ??? <T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
