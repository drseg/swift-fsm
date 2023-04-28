import Foundation

struct GivenNode: Node {
    struct Output {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [Action],
            groupID: UUID,
            isOverride: Bool
        
        init(
            _ state: AnyTraceable,
            _ match: Match,
            _ event: AnyTraceable,
            _ nextState: AnyTraceable,
            _ actions: [Action],
            _ groupID: UUID,
            _ isOverride: Bool
        ) {
            self.state = state
            self.match = match
            self.event = event
            self.nextState = nextState
            self.actions = actions
            self.groupID = groupID
            self.isOverride = isOverride
        }
    }
    
    let states: [AnyTraceable]
    var rest: [any Node<DefaultIO>] = []
    
    func combinedWithRest(_ rest: [DefaultIO], ignoreErrors: Bool) -> [Output] {
        states.reduce(into: []) { result, state in
            rest.forEach {
                result.append(Output(state,
                                     $0.match,
                                     $0.event!,
                                     $0.state ?? state,
                                     $0.actions,
                                     $0.groupID,
                                     $0.isOverride))
            }
        }
    }
}
