import Foundation

class ActionsNodeBase: OverridableNode {
    let actions: [AnyAction]
    var rest: [any SyntaxNode<RawSyntaxDTO>]

    init(
        actions: [AnyAction] = [],
        rest: [any SyntaxNode<RawSyntaxDTO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.actions = actions
        self.rest = rest
        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }
    
    func makeOutput(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        rest.reduce(into: []) {
            $0.append(
                RawSyntaxDTO(
                    $1.descriptor,
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

class ActionsNode: ActionsNodeBase, SyntaxNode {
    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        makeOutput(rest) ??? makeDefaultIO(actions: actions)
    }
}

class ActionsBlockNode: ActionsNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int

    init(
        actions: [AnyAction],
        rest: [any SyntaxNode<Input>],
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
    
    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        makeOutput(rest)
    }
}
