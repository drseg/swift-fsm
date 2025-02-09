import Foundation

class MatchingNodeBase: OverridableNode {
    let descriptor: MatchDescriptorChain
    var rest: [any SyntaxNode<RawSyntaxDTO>]

    init(
        descriptor: MatchDescriptorChain,
        rest: [any SyntaxNode<RawSyntaxDTO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.descriptor = descriptor
        self.rest = rest
        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }

    func makeOutput(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        rest.reduce(into: []) {
            $0.append(RawSyntaxDTO($1.descriptor.prepend(descriptor),
                                $1.event,
                                $1.state,
                                $1.actions,
                                overrideGroupID,
                                isOverride))
        }
    }
}

class MatchingNode: MatchingNodeBase, SyntaxNode {
    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        makeOutput(rest) ??? makeDefaultIO(match: descriptor)
    }
}

class MatchingBlockNode: MatchingNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int

    init(
        descriptor: MatchDescriptorChain,
        rest: [any SyntaxNode<Input>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false,
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line

        super.init(descriptor: descriptor,
                   rest: rest,
                   overrideGroupID: overrideGroupID,
                   isOverride: isOverride)
    }

    func combinedWith(_ rest: [RawSyntaxDTO]) -> [RawSyntaxDTO] {
        makeOutput(rest)
    }
}
