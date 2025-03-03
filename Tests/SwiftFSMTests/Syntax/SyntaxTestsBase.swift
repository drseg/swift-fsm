import Foundation
import Testing
import Numerics
@testable import SwiftFSM

class SyntaxTestsBase: ExpandedSyntaxBuilder {
    static let defaultOutput = "pass"
    static let defaultOutputWithEvent =
        "\(SyntaxTestsBase.defaultOutput), event: \(SyntaxTestsBase.defaultEvent)"
    static let defaultEvent = 111

    typealias State = Int
    typealias Event = Int

    typealias Define = Syntax.Define<State, Event>
    typealias Matching = Syntax.Matching<State, Event>
    typealias Condition = Syntax.Condition<State, Event>
    typealias When = Syntax.When<State, Event>
    typealias Then = Syntax.Then<State, Event>
    typealias Actions = Syntax.Actions
    typealias Override = Syntax.Override

    typealias MatchingWhenThen = Syntax.MatchingWhenThen
    typealias MatchingWhen = Syntax.MatchingWhen

    typealias AnyNode = any SyntaxNode

    var output = ""

    func pass() { output += Self.defaultOutput }
    func passAsync() async { pass() }
    func passWithEvent(_ event: Event) {
        output += Self.defaultOutput + ", event: " + String(event)
    }
    func passWithEventAsync(_ event: Event) async {
        passWithEvent(event)
    }

    func assertMatching(
        _ m: Matching,
        any: any Predicate...,
        all: any Predicate...,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        #expect(m.node.rest.isEmpty, sourceLocation: location)
        
        await assertMatchNode(
            m.node,
            any: [any],
            all: all,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertCondition(
        _ c: Condition,
        expected: Bool,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        #expect(c.node.rest.isEmpty, sourceLocation: location)
        
        let condition = c.node.descriptor.condition?()
        #expect(expected == condition, sourceLocation: location)
        
        await assertMatchNode(
            c.node,
            condition: expected,
            sutFile: sf,
            sutLine: sl,
            location: location)
    }

    func assertMatchNode(
        _ node: MatchingNodeBase,
        any: [[any Predicate]] = [],
        all: [any Predicate] = [],
        condition expectedCondition: Bool? = nil,
        caller: String = "matching",
        sutFile sf: String = #file,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let any = any.map { $0.erased() }.filter { !$0.isEmpty }
        let actualCondition = node.descriptor.condition?()

        #expect(
            any == node.descriptor.matchingAny,
            sourceLocation: location
        )
        
        #expect(
            all.erased() == node.descriptor.matchingAll,
            sourceLocation: location
        )
        
        #expect(
            actualCondition == expectedCondition,
            sourceLocation: location
        )
        
        #expect(
            node.descriptor.file == sf,
            sourceLocation: location
        )
        
        let line = Double(node.descriptor.line)
        #expect(
            line.isApproximatelyEqual(to: Double(sl), relativeTolerance: 1),
            sourceLocation: location
        )

        if let node = node as? MatchingBlockNode {
            assertNeverEmptyNode(
                node,
                caller: caller,
                sutFile: sf,
                sutLine: sl,
                location: location)
        }
    }

    func assertWhen(
        _ w: When,
        events: [Int] = [1, 2],
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(w.node.rest.isEmpty, sourceLocation: location)
        
        assertWhenNode(
            w.node,
            events: events,
            sutFile: sf,
            
            sutLine: sl,
            location: location
        )
    }

    func assertThen(
        _ t: Then,
        state: Int? = 1,
        sutFile sf: String? = nil,
        sutLine sl: Int? = #line,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(t.node.rest.isEmpty, sourceLocation: location)
        
        assertThenNode(
            t.node,
            state: state,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertWhenNode(
        _ node: WhenNodeBase,
        events: [Int] = [1, 2],
        sutFile sf: String = #file,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) {
        let files = [String](repeating: sf, count: events.count)
        let lines = [Int](repeating: sl, count: events.count)

        #expect(events == node.events.map { $0.base as! Int }, sourceLocation: location)
        #expect(files == node.events.map(\.file), sourceLocation: location)
        
        zip(lines, node.events.map(\.line)).forEach {
            #expect(
                Double($0.0).isApproximatelyEqual(to: Double($0.1), absoluteTolerance: 1),
                sourceLocation: location
            )
        }

        if let node = node as? any NeverEmptyNode {
            assertNeverEmptyNode(
                node,
                caller: "when",
                sutFile: sf,
                
                sutLine: sl,
                location: location)
        }
    }

    func assertThenNode(
        _ n: ThenNodeBase,
        state: State?,
        sutFile sf: String? = nil,
        sutLine sl: Int?,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(state == n.state?.base as? State, sourceLocation: location)
        #expect(sf == n.state?.file, sourceLocation: location)
        
        let expLine = Double(sl ?? 0)
        let actLine = Double(n.state?.line ?? 0)
        
        #expect(
            expLine.isApproximatelyEqual(to: actLine, absoluteTolerance: 1),
            sourceLocation: location
        )

        if let node = n as? ThenBlockNode {
            assertNeverEmptyNode(
                node,
                caller: "then",
                sutFile: sf,
                sutLine: sl ?? -1,
                location: location)
        }
    }

    func assertActionsThenNode(
        _ n: ActionsNodeBase,
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String,
        state: State?,
        sutFile sf: String? = #file,
        sutLine sl: Int?,
        location: SourceLocation = #_sourceLocation
    ) async {
        let thenNode = n.rest.first as! ThenNode
        assertThenNode(
            thenNode,
            state: state,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
        
        await assertActions(
            n.actions,
            event: e,
            expectedOutput: eo,
            location: location
        )
    }

    func assertActionsMatchNode(
        _ n: ActionsNodeBase,
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String,
        state: State?,
        sutFile sf: String = #file,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let matchNode = n.rest.first as! MatchingNode
        await assertMatchNode(
            matchNode,
            all: [P.a],
            sutFile: sf,
            sutLine: sl,
            location: location
        )
        
        await assertActions(
            n.actions,
            event: e,
            expectedOutput: eo,
            location: location
        )
    }

    func assertNeverEmptyNode(
        _ node: any NeverEmptyNode,
        caller: String,
        sutFile sf: String? = #file,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(sf == node.file, sourceLocation: location)
        
        #expect(
            Double(sl).isApproximatelyEqual(to: Double(node.line), absoluteTolerance: 1),
            sourceLocation: location
        )
        
        #expect(caller == node.caller, sourceLocation: location)
    }

    func assertMWTA(
        _ n: AnyNode,
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode
        let match = when.rest.first as! MatchingNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(1 == then.rest.count, sourceLocation: location)
        #expect(1 == when.rest.count, sourceLocation: location)
        #expect(0 == match.rest.count, sourceLocation: location)

        await assertActionsThenNode(
            actions,
            event: e,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            sutLine: sl,
            location: location
        )

        assertWhenNode(
            when,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
        
        await assertMatchNode(
            match,
            all: [P.a],
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertMWA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode
        let match = when.rest.first as! MatchingNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(1 == when.rest.count, sourceLocation: location)
        #expect(0 == match.rest.count, sourceLocation: location)

        await assertActions(
            actions.actions,
            event: event,
            expectedOutput: eo,
            location: location
        )
        
        assertWhenNode(
            when,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
        
        await assertMatchNode(
            match,
            all: [P.a],
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertMTA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let match = then.rest.first as! MatchingNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(1 == then.rest.count, sourceLocation: location)
        #expect(0 == match.rest.count, sourceLocation: location)

        await assertActionsThenNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            sutLine: sl,
            location: location
        )

        await assertMatchNode(
            match,
            all: [P.a],
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertWTA(
        _ n: AnyNode,
        event: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode
        let when = then.rest.first as! WhenNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(1 == then.rest.count, sourceLocation: location)
        #expect(0 == when.rest.count, sourceLocation: location)

        await assertActionsThenNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            sutLine: sl,
            location: location
        )

        assertWhenNode(when, sutFile: sf,  sutLine: sl, location: location)
    }

    func assertWA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let when = actions.rest.first as! WhenNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(0 == when.rest.count, sourceLocation: location)

        await assertActions(
            actions.actions,
            event: event,
            expectedOutput: eo,
            location: location
        )
        
        assertWhenNode(
            when,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertTA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let then = actions.rest.first as! ThenNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(0 == then.rest.count, sourceLocation: location)

        await assertActionsThenNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertMA(
        _ n: AnyNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = SyntaxTestsBase.defaultOutput,
        sutFile sf: String = #file,
        sutLine sl: Int = #line,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actions = n as! ActionsNode
        let match = actions.rest.first as! MatchingNode

        #expect(1 == actions.rest.count, sourceLocation: location)
        #expect(0 == match.rest.count, sourceLocation: location)

        await assertActionsMatchNode(
            actions,
            event: event,
            expectedOutput: eo,
            state: 1,
            sutFile: sf,
            sutLine: sl,
            location: location
        )
    }

    func assertActions(
        _ actions: [Action],
        expectedOutput eo: String,
        location: SourceLocation = #_sourceLocation
    ) async {
        await assertActions(
            actions.map(AnyAction.init),
            expectedOutput: eo,
            location: location
        )
    }

    func assertActions(
        _ actions: [AnyAction],
        event e: Event = SyntaxTestsBase.defaultEvent,
        expectedOutput eo: String,
        location: SourceLocation = #_sourceLocation
    ) async {
        await actions.executeAll(e)
        #expect(eo == output, sourceLocation: location)
        output = ""
    }
}
