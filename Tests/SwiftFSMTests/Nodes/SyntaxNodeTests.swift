import Testing
import Foundation
@testable import SwiftFSM

class SyntaxNodeTests {
    let s1: AnyTraceable = "S1", s2: AnyTraceable = "S2", s3: AnyTraceable = "S3"
    let e1: AnyTraceable = "E1", e2: AnyTraceable = "E2", e3: AnyTraceable = "E3"
    
    var actionsOutput = ""
    var onEntryOutput = ""
    var onExitOutput = ""
    
    var actions: [AnyAction] {
        [AnyAction({ self.actionsOutput += "1" }),
         AnyAction({ self.actionsOutput += "2" })]
    }
    
    var onEntry: [AnyAction] {
        [AnyAction({ self.actionsOutput += "<" }),
         AnyAction({ self.actionsOutput += "<" })]
    }
    
    var onExit: [AnyAction] {
        [AnyAction({ self.actionsOutput += ">" }),
         AnyAction({ self.actionsOutput += ">" })]
    }
    
    var actionsNode: ActionsNode {
        ActionsNode(actions: actions)
    }
    
    var thenNode: ThenNode {
        ThenNode(state: s1, rest: [actionsNode])
    }
    
    var whenNode: WhenNode {
        WhenNode(events: [e1, e2], rest: [thenNode])
    }
    
    var m1: MatchDescriptorChain {
        MatchDescriptorChain(any: [[P.a.erased()]],
              all: [Q.a.erased()],
              condition: { false },
              file: "null",
              line: -1)
    }
    
    func givenNode(thenState: AnyTraceable?, actionsNode: ActionsNode) -> GivenNode {
        let t = ThenNode(state: thenState, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchingNode(descriptor: m1, rest: [w])
        
        return GivenNode(states: [s1, s2], rest: [m])
    }
    
    func assertEqual(
        _ lhs: RawSyntaxDTO?,
        _ rhs: RawSyntaxDTO?,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(
            lhs?.descriptor == rhs?.descriptor &&
            lhs?.event == rhs?.event &&
            lhs?.state == rhs?.state,
            "\(String(describing: lhs)) does not equal \(String(describing: rhs))",
            sourceLocation: location
        )
    }
    
    func assertEqual(lhs: [MSES], rhs: [MSES], location: SourceLocation = #_sourceLocation) {
        #expect(
            isEqual(lhs: lhs, rhs: rhs),
            "\(lhs.description) does not equal \(rhs.description)",
            sourceLocation: location
        )
    }
    
    
    func isEqual(lhs: [MSES], rhs: [MSES]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (lhs, rhs) in zip(lhs, rhs) {
            guard lhs.match.resolve() == rhs.match.resolve() &&
                    lhs.state == rhs.state &&
                    lhs.event == rhs.event &&
                    lhs.nextState == rhs.nextState else { return false }
        }
        
        return true
    }
    
    func randomisedTrace(_ base: String) -> AnyTraceable {
        AnyTraceable(
            base,
            file: UUID().uuidString,
            line: Int.random(in: 0...Int.max)
        )
    }
    
    func assertEmptyThen(
        _ t: ThenNode,
        thenState: AnyTraceable? = "S1",
        location: SourceLocation = #_sourceLocation
    ) throws {
        let finalised = t.resolve()
        let result = finalised.0
        let errors = finalised.1
        
        try #require(result.count == 1, sourceLocation: location)
        #expect(errors.isEmpty, sourceLocation: location)
        #expect(thenState == result[0].state, sourceLocation: location)
        #expect(result[0].actions.isEmpty, sourceLocation: location)
    }
    
    func assertThenWithActions(
        expected: String,
        _ t: ThenNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        let finalised = t.resolve()
        let result = finalised.0
        let errors = finalised.1
        
        #expect(errors.isEmpty, sourceLocation: location)
        #expect(result[0].state == s1, sourceLocation: location)
        
        await assertActions(
            result.map(\.actions).flattened,
            expectedOutput: expected,
            location: location
        )
    }
    
    func assertEmptyNodeWithoutError(
        _ n: some SyntaxNode,
        location: SourceLocation = #_sourceLocation
    ) {
        let f = n.resolve()
        
        #expect(f.output.isEmpty, "Output not empty: \(f.0)", sourceLocation: location)
        #expect(f.errors.isEmpty, "Errors not empty: \(f.1)", sourceLocation: location)
    }
    
    func assertEmptyNodeWithError(
        _ n: some NeverEmptyNode,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(
            n.resolve().errors as? [EmptyBuilderError] ==
            [EmptyBuilderError(caller: n.caller, file: n.file, line: n.line)],
            sourceLocation: location
        )
    }
    
    func assertWhen(
        state: AnyTraceable?,
        actionsCount: Int,
        actionsOutput: String,
        node: WhenNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        let result = node.resolve().0
        let errors = node.resolve().1
        
        for i in 0..<2 {
            #expect(state == result[i].state, sourceLocation: location)
            #expect(actionsCount == result[i].actions.count, sourceLocation: location)
            await result.executeAll()
        }
        
        #expect(e1 == result[0].event, sourceLocation: location)
        #expect(e2 == result[1].event, sourceLocation: location)
        
        #expect(actionsOutput == actionsOutput, sourceLocation: location)
        #expect(errors.isEmpty, sourceLocation: location)
    }
    
    func assertMatch(
        _ m: MatchingNode,
        location: SourceLocation = #_sourceLocation
    ) async throws {
        let finalised = m.resolve()
        let result = finalised.0
        let errors = finalised.1
        
        #expect(errors.isEmpty, sourceLocation: location)
        try #require(result.count == 2, sourceLocation: location)
        
        assertEqual(
            result[0],
            RawSyntaxDTO(
                MatchDescriptorChain(),
                e1,
                s1,
                []
            ),
            location: location
        )
        
        assertEqual(
            result[1],
            RawSyntaxDTO(
                MatchDescriptorChain(),
                e2,
                s1,
                []
            ),
            location: location
        )
        
        await assertActions(
            result.map(\.actions).flattened,
            expectedOutput: "1212",
            location: location
        )
    }
    
    func assertGivenNode(
        expected: [MSES],
        actionsOutput: String,
        node: GivenNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        let finalised = node.resolve()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(
            lhs: expected,
            rhs: result.map { MSES($0.descriptor, $0.state, $0.event, $0.nextState) },
            location: location
        )
        
        await result.map(\.actions).flattened.executeAll()
        #expect(actionsOutput == actionsOutput, sourceLocation: location)
        #expect(errors.isEmpty, sourceLocation: location)
    }
    
    func assertDefineNode(
        expected: [MSES],
        actionsOutput: String,
        node: DefineNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        let finalised = node.resolve()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(
            lhs: expected,
            rhs: result.map { MSES($0.match, $0.state, $0.event, $0.nextState) },
            location: location
        )
        
        for node in result {
            await node.onEntry.executeAll()
            await node.actions.executeAll()
            await node.onExit.executeAll()
        }
        
        #expect(errors.isEmpty, sourceLocation: location)
        #expect(actionsOutput == actionsOutput, sourceLocation: location)
    }
    
    func assertDefaultIONodeChains(
        node: any RawDTONode,
        expectedMatch: MatchDescriptorChain = MatchDescriptorChain(any: P.a, all: Q.a),
        expectedEvent: AnyTraceable = "E1",
        expectedState: AnyTraceable = "S1",
        expectedOutput: String = "chain",
        location: SourceLocation = #_sourceLocation
    ) async throws {
        let nodeChains: [any SyntaxNode<RawSyntaxDTO>] = {
            let nodes: [any RawDTONode] =
            [MatchingNode(descriptor: MatchDescriptorChain(any: P.a, all: Q.a)),
             WhenNode(events: [e1]),
             ThenNode(state: s1),
             ActionsNode(actions: [AnyAction({ self.actionsOutput += "chain" })])]

            return nodes.permutations(ofCount: 4).reduce(into: []) {
                var one = $1[0].copy(),
                    two = $1[1].copy(),
                    three = $1[2].copy(),
                    four = $1[3].copy()
                
                three.rest.append(four as! any SyntaxNode<RawSyntaxDTO>)
                two.rest.append(three as! any SyntaxNode<RawSyntaxDTO>)
                one.rest.append(two as! any SyntaxNode<RawSyntaxDTO>)
                
                $0.append(one as! any SyntaxNode<RawSyntaxDTO>)
            }
        }()
        
        for n in nodeChains {
            var node = node.copy()
            node.rest.append(n)
            
            let output = node.resolve()
            let results = output.0
            
            try #require(results.count == 1, sourceLocation: location)
                                    
            let result = results[0]
            
            let actualPredicates = result.descriptor.resolve()
            let expectedPredicates = expectedMatch.resolve()
            
            #expect(
                expectedPredicates == actualPredicates,
                sourceLocation: location
            )
            
            #expect(
                expectedEvent == result.event,
                sourceLocation: location
            )
            
            #expect(
                expectedState == result.state,
                sourceLocation: location
            )
            
            #expect(
                testGroupID == result.overrideGroupID,
                sourceLocation: location
            )
            
            #expect(
                result.isOverride,
                sourceLocation: location
            )
            
            await assertActions(
                result.actions,
                expectedOutput: expectedOutput,
                location: location
            )
        }
    }
    
    func assertActions(
        _ actions: [AnyAction]?,
        expectedOutput: String?,
        location: SourceLocation = #_sourceLocation
    ) async {
        await actions?.executeAll()
        #expect(actionsOutput == expectedOutput, sourceLocation: location)
        actionsOutput = ""
    }
}

class DefineConsumer: SyntaxNodeTests {
    func defineNode(
        _ g: AnyTraceable,
        _ m: MatchDescriptorChain,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        entry: [AnyAction]? = nil,
        exit: [AnyAction]? = nil,
        overrideGroupID: UUID = testGroupID,
        isOverride: Bool = false
    ) -> DefineNode {
        let actions = ActionsNode(
            actions: actions,
            overrideGroupID: overrideGroupID,
            isOverride: isOverride
        )
        
        let then = ThenNode(
            state: t,
            rest: [actions],
            overrideGroupID: overrideGroupID,
            isOverride: isOverride
        )
        
        let when = WhenNode(
            events: [w],
            rest: [then],
            overrideGroupID: overrideGroupID,
            isOverride: isOverride
        )
        
        let match = MatchingNode(
            descriptor: m,
            rest: [when],
            overrideGroupID: overrideGroupID,
            isOverride: isOverride
        )
        
        let given = GivenNode(states: [g], rest: [match])
        
        return .init(
            onEntry: entry ?? [],
            onExit: exit ?? [],
            rest: [given],
            file: "null",
            line: -1
        )
    }
}

extension Collection {
    func executeAll() async where Element == RawSyntaxDTO {
        for action in map(\.actions).flattened {
            await action()
        }
    }

    func executeAll<Event: FSMHashable>(
        _ event: Event = "TILT"
    ) async where Element == AnyAction {
        for action in self {
            await action(event)
        }
    }
}

let testGroupID = UUID()

protocol RawDTONode: SyntaxNode where Output == RawSyntaxDTO, Input == Output {
    func copy() -> Self
}

extension ActionsNode: RawDTONode {
    func copy() -> ActionsNode {
        ActionsNode(
            actions: actions,
            rest: rest,
            overrideGroupID: testGroupID,
            isOverride: true
        )
    }
}

extension ThenNode: RawDTONode {
    func copy() -> ThenNode {
        ThenNode(
            state: state,
            rest: rest,
            overrideGroupID: testGroupID,
            isOverride: true
        )
    }
}

extension WhenNode: RawDTONode {
    func copy() -> WhenNode {
        WhenNode(
            events: events,
            rest: rest,
            overrideGroupID: testGroupID,
            isOverride: true
        )
    }
}

extension MatchingNode: RawDTONode {
    func copy() -> MatchingNode {
        MatchingNode(
            descriptor: descriptor,
            rest: rest,
            overrideGroupID: testGroupID,
            isOverride: true
        )
    }
}

struct MSES {
    let match: MatchDescriptorChain,
        state: AnyTraceable,
        event: AnyTraceable,
        nextState: AnyTraceable
    
    init(
        _ match: MatchDescriptorChain,
        _ state: AnyTraceable,
        _ event: AnyTraceable,
        _ nextState: AnyTraceable
    ) {
        self.match = match
        self.state = state
        self.event = event
        self.nextState = nextState
    }
}

extension AnyTraceable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value, file: "null", line: -1)
    }
}

extension AnyTraceable: CustomStringConvertible {
    public var description: String {
        base.description
    }
}
