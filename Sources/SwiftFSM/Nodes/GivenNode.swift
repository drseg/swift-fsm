import Foundation

struct GivenNode: Node {
    struct Output {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [Action]
        
        init(
            _ state: AnyTraceable,
             _ match: Match,
            _ event: AnyTraceable,
            _ nextState: AnyTraceable,
            _ actions: [Action]
        ) {
            self.state = state
            self.match = match
            self.event = event
            self.nextState = nextState
            self.actions = actions
        }
    }
    
    let states: [AnyTraceable]
    var rest: [any Node<DefaultIO>] = []
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [Output] {
        states.reduce(into: []) { result, state in
            rest.forEach {
                result.append(Output(state, $0.match, $0.event!, $0.state ?? state, $0.actions))
            }
        }
    }
}
