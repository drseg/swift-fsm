import Foundation

class ActionsNodeBase: OverridableNode {
    let actions: [AnyAction]
    var rest: [any Node<DefaultIO>]

    init(
        actions: [AnyAction] = [],
        rest: [any Node<DefaultIO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.actions = actions
        self.rest = rest
        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }
    
    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append(
                DefaultIO(
                    $1.match,
                    $1.event,
                    $1.state,
                    actions + $1.actions,
                    overrideGroupID,
                    isOverride
                )
            )
        }
    }
}

class ActionsNode: ActionsNodeBase, Node {
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(actions: actions)
    }
}

class ActionsBlockNode: ActionsNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int

    init(
        actions: [AnyAction],
        rest: [any Node<Input>],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false,
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(
            actions: actions,
            rest: rest,
            overrideGroupID: overrideGroupID,
            isOverride: isOverride
        )
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest)
    }
}
