import Foundation

class MatchNodeBase: OverridableNode {
    let match: Match
    var rest: [any Node<DefaultIO>]

    init(
        match: Match,
        rest: [any Node<DefaultIO>] = [],
        overrideGroupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.match = match
        self.rest = rest
        super.init(overrideGroupID: overrideGroupID, isOverride: isOverride)
    }

    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append(DefaultIO($1.match.prepend(match),
                                $1.event,
                                $1.state,
                                $1.actions,
                                overrideGroupID,
                                isOverride))
        }
    }
}

class MatchNode: MatchNodeBase, Node {
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(match: match)
    }
}

class MatchBlockNode: MatchNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int

    init(
        match: Match,
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

        super.init(match: match,
                   rest: rest,
                   overrideGroupID: overrideGroupID,
                   isOverride: isOverride)
    }

    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest)
    }
}
