import XCTest
import Algorithms
@testable import SwiftFSM

class SyntaxNodeTests: XCTestCase {
    let s1: AnyTraceable = "S1", s2: AnyTraceable = "S2", s3: AnyTraceable = "S3"
    let e1: AnyTraceable = "E1", e2: AnyTraceable = "E2", e3: AnyTraceable = "E3"
    
    var actionsOutput = ""
    var onEntryOutput = ""
    var onExitOutput = ""
    
    var actions: [Action] {
        [{ self.actionsOutput += "1" },
         { self.actionsOutput += "2" }]
    }
    
    var onEntry: [Action] {
        [{ self.actionsOutput += "<" },
         { self.actionsOutput += "<" }]
    }
    
    var onExit: [Action] {
        [{ self.actionsOutput += ">" },
         { self.actionsOutput += ">" }]
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
    
    var m1: Match {
        Match(any: [[P.a.erased()]],
              all: [Q.a.erased()],
              condition: { false },
              file: "null",
              line: -1)
    }
    
    func givenNode(thenState: AnyTraceable?, actionsNode: ActionsNode) -> GivenNode {
        let t = ThenNode(state: thenState, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w])
        
        return GivenNode(states: [s1, s2], rest: [m])
    }
    
    func assertEqual(
        _ lhs: DefaultIO?,
        _ rhs: DefaultIO?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(lhs?.match == rhs?.match &&
                      lhs?.event == rhs?.event &&
                      lhs?.state == rhs?.state,
                      "\(String(describing: lhs)) does not equal \(String(describing: rhs))",
                      file: file,
                      line: line)
    }
    
    func assertEqual(lhs: [MSES], rhs: [MSES], file: StaticString = #file, line: UInt) {
        XCTAssertTrue(isEqual(lhs: lhs, rhs: rhs),
                      "\(lhs.description) does not equal \(rhs.description)",
                      file: file,
                      line: line)
    }
    
    
    func isEqual(lhs: [MSES], rhs: [MSES]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (lhs, rhs) in zip(lhs, rhs) {
            guard lhs.match.finalised() == rhs.match.finalised() &&
                    lhs.state == rhs.state &&
                    lhs.event == rhs.event &&
                    lhs.nextState == rhs.nextState else { return false }
        }
        
        return true
    }
    
    func randomisedTrace(_ base: String) -> AnyTraceable {
        AnyTraceable(base,
                     file: UUID().uuidString,
                     line: Int.random(in: 0...Int.max))
    }
    
    func assertEmptyThen(
        _ t: ThenNode,
        thenState: AnyTraceable? = "S1",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let finalised = t.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        guard assertCount(result, expected: 1, file: file, line: line) else { return }
        
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
        XCTAssertEqual(thenState, result[0].state, file: file, line: line)
        XCTAssertTrue(result[0].actions.isEmpty, file: file, line: line)
    }
    
    func assertThenWithActions(
        expected: String,
        _ t: ThenNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let finalised = t.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
        XCTAssertEqual(result[0].state, s1, file: file, line: line)
        assertActions(result.map(\.actions).flattened,
                      expectedOutput: expected,
                      file: file,
                      line: line)
    }
    
    func assertEmptyNodeWithoutError(
        _ n: some UnsafeNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let f = n.finalised()
        
        XCTAssertTrue(f.output.isEmpty, "Output not empty: \(f.0)", file: file, line: line)
        XCTAssertTrue(f.errors.isEmpty, "Errors not empty: \(f.1)", file: file, line: line)
    }
    
    func assertEmptyNodeWithError(
        _ n: some NeverEmptyNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(n.finalised().errors as? [EmptyBuilderError],
                       [EmptyBuilderError(caller: n.caller, file: n.file, line: n.line)],
                       file: file,
                       line: line)
    }
    
    func assertWhen(
        state: AnyTraceable?,
        actionsCount: Int,
        actionsOutput: String,
        node: WhenNode,
        file: StaticString = #file,
        line: UInt
    ) {
        let result = node.finalised().0
        let errors = node.finalised().1
        
        (0..<2).forEach {
            XCTAssertEqual(state, result[$0].state, file: file, line: line)
            XCTAssertEqual(actionsCount, result[$0].actions.count, file: file, line: line)
            result.executeAll()
        }
        
        XCTAssertEqual(e1, result[0].event, file: file, line: line)
        XCTAssertEqual(e2, result[1].event, file: file,  line: line)
        
        XCTAssertEqual(actionsOutput, actionsOutput, file: file, line: line)
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
    }
    
    @discardableResult
    func assertCount(
        _ actual: (any Collection)?,
        expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        guard actual?.count ?? -1 == expected else {
            XCTFail("Incorrect count: \(actual?.count ?? -1), expected: \(expected)",
                    file: file,
                    line: line)
            return false
        }
        return true
    }
    
    func assertMatch(_ m: MatchNode, file: StaticString = #file, line: UInt = #line) {
        let finalised = m.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
        XCTAssertEqual(result.count, 2, file: file, line: line)
        
        assertEqual(result[0], DefaultIO(Match(), e1, s1, []), file: file, line: line)
        assertEqual(result[1], DefaultIO(Match(), e2, s1, []), file: file, line: line)
        
        assertActions(result.map(\.actions).flattened,
                      expectedOutput: "1212",
                      file: file,
                      line: line)
    }
    
    func assertGivenNode(
        expected: [MSES],
        actionsOutput: String,
        node: GivenNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let finalised = node.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { MSES($0.match, $0.state, $0.event, $0.nextState) },
                    file: file,
                    line: line)
        
        result.map(\.actions).flattened.executeAll()
        XCTAssertEqual(actionsOutput, actionsOutput, file: file, line: line)
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
    }
    
    func assertDefineNode(
        expected: [MSES],
        actionsOutput: String,
        node: DefineNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let finalised = node.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { MSES($0.match, $0.state, $0.event, $0.nextState) },
                    file: file,
                    line: line)
        
        result.forEach {
            $0.onEntry.executeAll()
            $0.actions.executeAll()
            $0.onExit.executeAll()
        }
        
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
        XCTAssertEqual(actionsOutput, actionsOutput, file: file, line: line)
    }
    
    func assertDefaultIONodeChains(
        node: any DefaultIONode,
        expectedMatch: Match = Match(any: P.a, all: Q.a),
        expectedEvent: AnyTraceable = "E1",
        expectedState: AnyTraceable = "S1",
        expectedOutput: String = "chain",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let nodeChains: [any UnsafeNode] = {
            let nodes: [any DefaultIONode] =
            [MatchNode(match: Match(any: P.a, all: Q.a)),
             WhenNode(events: [e1]),
             ThenNode(state: s1),
             ActionsNode(actions: [{ self.actionsOutput += "chain" }])]
                        
            return nodes.permutations(ofCount: 4).reduce(into: []) {
                var one = $1[0].copy(),
                    two = $1[1].copy(),
                    three = $1[2].copy(),
                    four = $1[3].copy()
                
                three.rest.append(four)
                two.rest.append(three)
                one.rest.append(two)
                
                $0.append(one)
            }
        }()
        
        nodeChains.forEach {
            var node = node.copy()
            node.rest.append($0)
            
            let output = node.finalised()
            let results = output.0
                        
            guard assertCount(results, expected: 1, file: file, line: line) else { return }
            
            let result = results[0]
            
            let actualPredicates = result.match.finalised()
            let expectedPredicates = expectedMatch.finalised()
            
            XCTAssertEqual(expectedPredicates, actualPredicates, file: file, line: line)
            XCTAssertEqual(expectedEvent, result.event, file: file, line: line)
            XCTAssertEqual(expectedState, result.state, file: file, line: line)
            
            XCTAssertEqual(testGroupID, result.groupID, file: file, line: line)
            XCTAssertEqual(true, result.isOverride, file: file, line: line)
            
            assertActions(result.actions, expectedOutput: expectedOutput, file: file, line: line)
        }
    }
    
    func assertActions(
        _ actions: [Action]?,
        expectedOutput: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        actions?.executeAll()
        XCTAssertEqual(actionsOutput, expectedOutput, file: file, line: line)
        actionsOutput = ""
    }
}

class DefineConsumer: SyntaxNodeTests {
    func defineNode(
        _ g: AnyTraceable,
        _ m: Match,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        entry: [Action]? = nil,
        exit: [Action]? = nil,
        groupID: UUID = testGroupID,
        isOverride: Bool = false
    ) -> DefineNode {
        let actions = ActionsNode(actions: actions, groupID: groupID, isOverride: isOverride)
        let then = ThenNode(state: t, rest: [actions], groupID: groupID, isOverride: isOverride)
        let when = WhenNode(events: [w], rest: [then], groupID: groupID, isOverride: isOverride)
        let match = MatchNode(match: m, rest: [when], groupID: groupID, isOverride: isOverride)
        let given = GivenNode(states: [g], rest: [match])
        
        return .init(onEntry: entry ?? [],
                     onExit: exit ?? [],
                     rest: [given],
                     file: "null",
                     line: -1)
    }
}

extension Collection {
    func executeAll() where Element == DefaultIO {
        map(\.actions).flattened.forEach { $0() }
    }
    
    func executeAll() where Element == Action {
        forEach { $0() }
    }
}

let testGroupID = UUID()

protocol DefaultIONode: UnsafeNode where Output == DefaultIO, Input == Output {
    func copy() -> Self
}

extension ActionsNode: DefaultIONode {
    func copy() -> Self {
        ActionsNode(actions: actions, rest: rest, groupID: testGroupID, isOverride: true) as! Self
    }
}

extension ThenNode: DefaultIONode {
    func copy() -> Self {
        ThenNode(state: state, rest: rest, groupID: testGroupID, isOverride: true) as! Self
    }
}

extension WhenNode: DefaultIONode {
    func copy() -> Self {
        WhenNode(events: events, rest: rest, groupID: testGroupID, isOverride: true) as! Self
    }
}

extension MatchNode: DefaultIONode {
    func copy() -> Self {
        MatchNode(match: match, rest: rest, groupID: testGroupID, isOverride: true) as! Self
    }
}

struct MSES {
    let match: Match,
        state: AnyTraceable,
        event: AnyTraceable,
        nextState: AnyTraceable
    
    init(_ match: Match, _ state: AnyTraceable, _ event: AnyTraceable, _ nextState: AnyTraceable) {
        self.match = match
        self.state = state
        self.event = event
        self.nextState = nextState
    }
}

extension [MSES] {
    var description: String {
        reduce(into: ["\n"]) {
            $0.append("(\($1.match), \($1.state), \($1.event), \($1.nextState))")
        }.joined(separator: "\n")
    }
}

extension AnyTraceable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(AnyHashable(value), file: "null", line: -1)
    }
}

extension AnyTraceable: CustomStringConvertible {
    public var description: String {
        base.description
    }
}
