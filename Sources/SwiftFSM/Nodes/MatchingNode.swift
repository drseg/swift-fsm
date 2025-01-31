import Foundation

class MatchingNodeBase: OverridableNode {
    let descriptor: MatchDescriptor
    var rest: [any Node<DefaultIO>]

    init(
        descriptor: MatchDescriptor,
        rest: [any Node<DefaultIO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.descriptor = descriptor
        self.rest = rest
        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }

    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append(DefaultIO($1.descriptor.prepend(descriptor),
                                $1.event,
                                $1.state,
                                $1.actions,
                                overrideGroupID,
                                isOverride))
        }
    }
}

class MatchingNode: MatchingNodeBase, Node {
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(match: descriptor)
    }
}

class MatchingBlockNode: MatchingNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int

    init(
        descriptor: MatchDescriptor,
        rest: [any Node<Input>] = [],
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

    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest)
    }
}
