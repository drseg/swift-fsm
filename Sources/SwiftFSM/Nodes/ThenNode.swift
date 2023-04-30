import Foundation

class ThenNodeBase: OverridableNode {
    let state: AnyTraceable?
    var rest: [any UnsafeNode]
    
    init(
        state: AnyTraceable?,
        rest: [any UnsafeNode] = [],
        groupID: UUID = UUID(),
        isOverride: Bool = false
    ) {
        self.state = state
        self.rest = rest
        super.init(groupID: groupID, isOverride: isOverride)
    }
    
    func makeOutput(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: []) {
            $0.append(DefaultIO($1.match,
                                $1.event,
                                state,
                                $1.actions,
                                groupID,
                                isOverride))
        }
    }
}

class ThenNode: ThenNodeBase, UnsafeNode {
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest) ??? makeDefaultIO(state: state)
    }
}

class ThenBlockNode: ThenNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        state: AnyTraceable?,
        rest: [any UnsafeNode],
        caller: String = #function,
        groupID: UUID = UUID(),
        isOverride: Bool = false,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(state: state,
                   rest: rest,
                   groupID: groupID,
                   isOverride: isOverride)
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        makeOutput(rest)
    }
}
