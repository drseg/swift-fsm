import XCTest
@testable import SwiftFSM

class SyntaxNodeTests: XCTestCase {
    let s1: AnyTraceable = "S1", s2: AnyTraceable = "S2", s3: AnyTraceable = "S3"
    let e1: AnyTraceable = "E1", e2: AnyTraceable = "E2", e3: AnyTraceable = "E3"
    
    var actionsOutput = ""
    var onEntryOutput = ""
    var onExitOutput = ""
    
    var actions: [AnyAction] {
        [{ self.actionsOutput += "1" },
         { self.actionsOutput += "2" }].map(AnyAction.init)
    }
    
    var onEntry: [AnyAction] {
        [{ self.actionsOutput += "<" },
         { self.actionsOutput += "<" }].map(AnyAction.init)
    }
    
    var onExit: [AnyAction] {
        [{ self.actionsOutput += ">" },
         { self.actionsOutput += ">" }].map(AnyAction.init)
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
    
    var m1: MatchDescriptor {
        MatchDescriptor(any: [[P.a.erased()]],
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
        _ lhs: DefaultIO?,
        _ rhs: DefaultIO?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(lhs?.descriptor == rhs?.descriptor &&
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
            guard lhs.match.resolved() == rhs.match.resolved() &&
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
        let finalised = t.resolved()
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
        let finalised = t.resolved()
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
        _ n: some Node,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let f = n.resolved()
        
        XCTAssertTrue(f.output.isEmpty, "Output not empty: \(f.0)", file: file, line: line)
        XCTAssertTrue(f.errors.isEmpty, "Errors not empty: \(f.1)", file: file, line: line)
    }
    
    func assertEmptyNodeWithError(
        _ n: some NeverEmptyNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(n.resolved().errors as? [EmptyBuilderError],
                       [EmptyBuilderError(caller: n.caller, file: n.file, line: n.line)],
                       file: file,
                       line: line)
    }
    
    @MainActor
    func assertWhen(
        state: AnyTraceable?,
        actionsCount: Int,
        actionsOutput: String,
        node: WhenNode,
        file: StaticString = #file,
        line: UInt
    ) {
        let result = node.resolved().0
        let errors = node.resolved().1
        
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
    
    func assertMatch(_ m: MatchingNode, file: StaticString = #file, line: UInt = #line) {
        let finalised = m.resolved()
        let result = finalised.0
        let errors = finalised.1
        
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
        XCTAssertEqual(result.count, 2, file: file, line: line)
        
        assertEqual(result[0], DefaultIO(MatchDescriptor(), e1, s1, []), file: file, line: line)
        assertEqual(result[1], DefaultIO(MatchDescriptor(), e2, s1, []), file: file, line: line)
        
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
        let finalised = node.resolved()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { MSES($0.descriptor, $0.state, $0.event, $0.nextState) },
                    file: file,
                    line: line)
        
        let expectation = expectation(description: "async action")
        Task {
            await result.map(\.actions).flattened.executeAll()
            XCTAssertEqual(actionsOutput, actionsOutput, file: file, line: line)
            XCTAssertTrue(errors.isEmpty, file: file, line: line)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }
    
    func assertDefineNode(
        expected: [MSES],
        actionsOutput: String,
        node: DefineNode,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let finalised = node.resolved()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { MSES($0.match, $0.state, $0.event, $0.nextState) },
                    file: file,
                    line: line)

        let expectation = expectation(description: "async action")
        Task {
            for node in result {
                await node.onEntry.executeAll()
                await node.actions.executeAll()
                await node.onExit.executeAll()
            }

            XCTAssertTrue(errors.isEmpty, file: file, line: line)
            XCTAssertEqual(actionsOutput, actionsOutput, file: file, line: line)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }
    
    func assertDefaultIONodeChains(
        node: any DefaultIONode,
        expectedMatch: MatchDescriptor = MatchDescriptor(any: P.a, all: Q.a),
        expectedEvent: AnyTraceable = "E1",
        expectedState: AnyTraceable = "S1",
        expectedOutput: String = "chain",
        file: StaticString = #file,
        line: UInt = #line
    ) {

        let actions = [{ self.actionsOutput += "chain" }]

        let nodeChains: [any Node<DefaultIO>] = {
            let nodes: [any DefaultIONode] =
            [MatchingNode(descriptor: MatchDescriptor(any: P.a, all: Q.a)),
             WhenNode(events: [e1]),
             ThenNode(state: s1),
             ActionsNode(actions: actions.map(AnyAction.init))]

            return nodes.permutations(ofCount: 4).reduce(into: []) {
                var one = $1[0].copy(),
                    two = $1[1].copy(),
                    three = $1[2].copy(),
                    four = $1[3].copy()
                
                three.rest.append(four as! any Node<DefaultIO>)
                two.rest.append(three as! any Node<DefaultIO>)
                one.rest.append(two as! any Node<DefaultIO>)
                
                $0.append(one as! any Node<DefaultIO>)
            }
        }()
        
        nodeChains.forEach {
            var node = node.copy()
            node.rest.append($0)
            
            let output = node.resolved()
            let results = output.0
                        
            guard assertCount(results, expected: 1, file: file, line: line) else { return }
            
            let result = results[0]
            
            let actualPredicates = result.descriptor.resolved()
            let expectedPredicates = expectedMatch.resolved()
            
            XCTAssertEqual(expectedPredicates, actualPredicates, file: file, line: line)
            XCTAssertEqual(expectedEvent, result.event, file: file, line: line)
            XCTAssertEqual(expectedState, result.state, file: file, line: line)
            
            XCTAssertEqual(testGroupID, result.overrideGroupID, file: file, line: line)
            XCTAssertEqual(true, result.isOverride, file: file, line: line)
            
            assertActions(result.actions, expectedOutput: expectedOutput, file: file, line: line)
        }
    }
    
    func assertActions(
        _ actions: [AnyAction]?,
        expectedOutput: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "async action")
        Task {
            await actions?.executeAll()
            XCTAssertEqual(actionsOutput, expectedOutput, file: file, line: line)
            actionsOutput = ""
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }
}

class DefineConsumer: SyntaxNodeTests {
    func defineNode(
        _ g: AnyTraceable,
        _ m: MatchDescriptor,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        entry: [AnyAction]? = nil,
        exit: [AnyAction]? = nil,
        overrideGroupID: UUID = testGroupID,
        isOverride: Bool = false
    ) -> DefineNode {
        let actions = ActionsNode(actions: actions, overrideGroupID: overrideGroupID, isOverride: isOverride)
        let then = ThenNode(state: t, rest: [actions], overrideGroupID: overrideGroupID, isOverride: isOverride)
        let when = WhenNode(events: [w], rest: [then], overrideGroupID: overrideGroupID, isOverride: isOverride)
        let match = MatchingNode(descriptor: m, rest: [when], overrideGroupID: overrideGroupID, isOverride: isOverride)
        let given = GivenNode(states: [g], rest: [match])
        
        return .init(onEntry: entry ?? [],
                     onExit: exit ?? [],
                     rest: [given],
                     file: "null",
                     line: -1)
    }
}

@MainActor
extension Collection {
    func executeAll() where Element == DefaultIO {
        map(\.actions).flattened.forEach { try! $0() }
    }

    func executeAll<Event: FSMHashable>(_ event: Event = "TILT") async where Element == AnyAction {
        for action in self {
            await action(event)
        }
    }
}

let testGroupID = UUID()

protocol DefaultIONode: Node where Output == DefaultIO, Input == Output {
    func copy() -> Self
}

extension ActionsNode: DefaultIONode {
    func copy() -> Self {
        ActionsNode(actions: actions, rest: rest, overrideGroupID: testGroupID, isOverride: true) as! Self
    }
}

extension ThenNode: DefaultIONode {
    func copy() -> Self {
        ThenNode(state: state, rest: rest, overrideGroupID: testGroupID, isOverride: true) as! Self
    }
}

extension WhenNode: DefaultIONode {
    func copy() -> Self {
        WhenNode(events: events, rest: rest, overrideGroupID: testGroupID, isOverride: true) as! Self
    }
}

extension MatchingNode: DefaultIONode {
    func copy() -> Self {
        MatchingNode(descriptor: descriptor, rest: rest, overrideGroupID: testGroupID, isOverride: true) as! Self
    }
}

struct MSES {
    let match: MatchDescriptor,
        state: AnyTraceable,
        event: AnyTraceable,
        nextState: AnyTraceable
    
    init(_ match: MatchDescriptor, _ state: AnyTraceable, _ event: AnyTraceable, _ nextState: AnyTraceable) {
        self.match = match
        self.state = state
        self.event = event
        self.nextState = nextState
    }
}

extension AnyTraceable: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value, file: "null", line: -1)
    }
}

extension AnyTraceable: @retroactive CustomStringConvertible {
    public var description: String {
        base.description
    }
}
