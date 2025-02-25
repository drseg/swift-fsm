import Foundation

struct GivenNode: SyntaxNode {
    struct Output {
        let state: AnyTraceable,
            descriptor: MatchDescriptorChain,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [AnyAction],
            overrideGroupID: UUID,
            isOverride: Bool

        init(
            _ state: AnyTraceable,
            _ match: MatchDescriptorChain,
            _ event: AnyTraceable,
            _ nextState: AnyTraceable,
            _ actions: [AnyAction],
            _ overrideGroupID: UUID,
            _ isOverride: Bool
        ) {
            self.state = state
            self.descriptor = match
            self.event = event
            self.nextState = nextState
            self.actions = actions
            self.overrideGroupID = overrideGroupID
            self.isOverride = isOverride
        }
    }

    let states: [AnyTraceable]
    var rest: [any SyntaxNode<RawSyntaxDTO>] = []

    func combinedWith(_ rest: [RawSyntaxDTO]) -> [Output] {
        states.reduce(into: []) { result, state in
            rest.forEach {
                result.append(Output(state,
                                     $0.descriptor,
                                     $0.event!,
                                     $0.state ?? state,
                                     $0.actions,
                                     $0.overrideGroupID,
                                     $0.isOverride))
            }
        }
    }
}
