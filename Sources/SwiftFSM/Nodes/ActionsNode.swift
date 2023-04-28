import Foundation

class ActionsNodeBase: OverridableNode {
    let actions: [Action]
    var rest: [any Node<DefaultIO>]
    
    init(
        actions: [Action] = [],
        rest: [any Node<DefaultIO>] = [],
        groupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.actions = actions
        self.rest = rest
        super.init(groupID: groupID, isOverride: isOverride)
    }
    
    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append(DefaultIO($1.match,
                                $1.event,
                                $1.state,
                                actions + $1.actions,
                                groupID,
                                isOverride))
        }
    }
}

class ActionsNode: ActionsNodeBase, Node {
    func combinedWithRest(_ rest: [DefaultIO], ignoreErrors: Bool) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(actions: actions)
    }
}

class ActionsBlockNode: ActionsNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        actions: [Action],
        rest: [any Node<Input>],
        groupID: UUID = UUID(),
        isOverride: Bool = false,
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(actions: actions,
                   rest: rest,
                   groupID: groupID,
                   isOverride: isOverride)
    }
    
    func combinedWithRest(_ rest: [DefaultIO], ignoreErrors: Bool) -> [DefaultIO] {
        makeOutput(rest)
    }
}
