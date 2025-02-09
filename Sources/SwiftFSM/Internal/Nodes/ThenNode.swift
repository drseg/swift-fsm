import Foundation

class ThenNodeBase: OverridableNode {
    let state: AnyTraceable?
    var rest: [any SyntaxNode<RawSyntaxDTO>]

    init(
        state: AnyTraceable?,
        rest: [any SyntaxNode<RawSyntaxDTO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.state = state
        self.rest = rest
        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }

    func makeOutput(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        rest.reduce(into: []) {
            $0.append(RawSyntaxDTO($1.descriptor,
                                $1.event,
                                state,
                                $1.actions,
                                overrideGroupID,
                                isOverride))
        }
    }
}

class ThenNode: ThenNodeBase, SyntaxNode {
    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        makeOutput(rest) ??? makeDefaultIO(state: state)
    }
}

class ThenBlockNode: ThenNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int

    init(
        state: AnyTraceable?,
        rest: [any SyntaxNode<Input>],
        caller: String = #function,
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line

        super.init(state: state,
                   rest: rest,
                   overrideGroupID: overrideGroupID,
                   isOverride: isOverride)
    }

    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        makeOutput(rest)
    }
}
