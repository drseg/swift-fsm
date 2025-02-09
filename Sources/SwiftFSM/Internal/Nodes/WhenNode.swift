import Foundation

class WhenNodeBase: OverridableNode {
    let events: [AnyTraceable]
    var rest: [any SyntaxNode<RawSyntaxDTO>]

    let caller: String
    let file: String
    let line: Int

    init(
        events: [AnyTraceable],
        rest: [any SyntaxNode<RawSyntaxDTO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false,
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.events = events
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line

        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }

    func makeOutput(_ rest: [RawSyntaxDTO], _ event: AnyTraceable) -> [RawSyntaxDTO] {
        rest.reduce(into: []) {
            $0.append(RawSyntaxDTO($1.descriptor,
                                event,
                                $1.state,
                                $1.actions,
                                overrideGroupID,
                                isOverride))
        }
    }
}

class WhenNode: WhenNodeBase, NeverEmptyNode {
    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        events.reduce(into: []) { output, event in
            output.append(contentsOf: makeOutput(rest, event) ??? makeDefaultIO(event: event))
        }
    }

    func findErrors() -> [Error] {
        makeError(if: events.isEmpty)
    }
}

class WhenBlockNode: WhenNodeBase, NeverEmptyNode {
    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        events.reduce(into: []) { output, event in
            output.append(contentsOf: makeOutput(rest, event))
        }
    }

    func findErrors() -> [Error] {
        makeError(if: events.isEmpty || rest.isEmpty)
    }
}
