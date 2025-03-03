import Testing
@testable import SwiftFSM

final class CompoundSyntaxTests: SyntaxTestsBase {
    func assertMW(
        _ mw: MatchingWhen<State, Event>,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        await assertMWNode(mw.node, sutLine: sl, location: location)
    }
    
    func assertMWNode<N: SyntaxNode>(
        _ n: N,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let whenNode = n as! WhenNode
        let matchNode = n.rest.first as! MatchingNode
        
        #expect(1 == whenNode.rest.count, sourceLocation: location)
        #expect(0 == matchNode.rest.count, sourceLocation: location)
        
        assertWhenNode(whenNode, sutLine: sl, location: location)
        await assertMatchNode(matchNode, all: [P.a], sutLine: sl, location: location)
    }
    
    @Test func matching() async {
        await assertMatching(matching(P.a), all: P.a)
        await assertMatching(matching(P.a, or: P.b, line: -1), any: P.a, P.b, sutLine: -1)
        await assertMatching(matching(P.a, and: Q.a, line: -1), all: P.a, Q.a, sutLine: -1)
        await assertMatching(
            matching(
                P.a,
                or: P.b,
                and: Q.a,
                R.a,
                line: -1
            ),
            any: P.a, P.b,
            all: Q.a, R.a,
            sutLine: -1
        )
    }
    
    @Test func condition() async {
        await assertCondition(condition({ true }), expected: true)
    }
            
    @Test func when() {
        assertWhen(when(1, or: 2))
        assertWhen(when(1), events: [1])
    }
    
    @Test func then() {
        assertThen(then(1), sutFile: #file)
        assertThen(then(), state: nil, sutLine: nil)
    }
    
    @Test func matchingWhen() async {
        await assertMW(matching(P.a) | when(1, or: 2), sutLine: #line)
    }

    @Test func matchingWhenThen() async {
        func assertMWT(
            _ mwt: MatchingWhenThen<Event>,
            sutLine sl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            let then = mwt.node
            let when = then.rest.first as! WhenNode
            
            #expect(1 == then.rest.count, sourceLocation: location)
            assertThenNode(
                then as! ThenNodeBase,
                state: 1,
                sutFile: #file,
                sutLine: sl,
                location: location
            )
            await assertMWNode(when, sutLine: sl)
        }
        
        await assertMWT(matching(P.a) | when(1, or: 2) | then(1), sutLine: #line)
    }
    
    @Test func matchingWhenThenActions() async {
        let mwta1 = matching(P.a) | when(1, or: 2) | then(1) | pass; let l1 = #line
        let mwta2 = matching(P.a) | when(1, or: 2) | then(1) | pass & pass; let l2 = #line

        await assertMWTA(mwta1.node, sutLine: l1)
        await assertMWTA(
            mwta2.node,
            expectedOutput: Self.defaultOutput + Self.defaultOutput,
            sutLine: l2
        )
    }

    @Test func matchingWhenThenActions_withEvent() async {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passWithEvent; let l2 = #line
        await assertMWTA(
            mwta.node,
            event: 111,
            expectedOutput: "pass, event: 111",
            sutLine: l2
        )
    }

    @Test func matchingWhenThenActionsAsync() async {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passAsync; let l1 = #line
        await assertMWTA(mwta.node, sutLine: l1)
    }

    @Test func matchingWhenThenActionsAsync_withEvent() async {
        let mwta = matching(P.a) | when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line
        await assertMWTA(
            mwta.node,
            event: 111,
            expectedOutput: "pass, event: 111",
            sutLine: l2
        )
    }

    @Test func whenThen() {
        func assertWT(
            _ wt: MatchingWhenThen<Event>,
            sutLine sl: Int,
            location: SourceLocation = #_sourceLocation
        ) {
            let then = wt.node
            let when = then.rest.first as! WhenNode

            #expect(1 == then.rest.count, sourceLocation: location)
            #expect(0 == when.rest.count, sourceLocation: location)

            assertThenNode(
                then as! ThenNodeBase,
                state: 1,
                sutFile: #file,
                sutLine: sl,
                location: location
            )
            assertWhenNode(when, sutLine: sl, location: location)
        }

        assertWT(when(1, or: 2) | then(1), sutLine: #line)
    }
    
    @Test func whenThenActions() async {
        let wta1 = when(1, or: 2) | then(1) | pass; let l1 = #line
        let wta2 = when(1, or: 2) | then(1) | pass & pass; let l2 = #line

        await assertWTA(wta1.node, sutLine: l1)
        await assertWTA(
            wta2.node,
            expectedOutput: Self.defaultOutput + Self.defaultOutput,
            sutLine: l2
        )
    }

    @Test func whenThenActionsAsync() async {
        let wta1 = when(1, or: 2) | then(1) | passAsync; let l1 = #line
        await assertWTA(wta1.node, sutLine: l1)
    }

    @Test func whenThenActions_withEvent() async {
        let wta2 = when(1, or: 2) | then(1) | passWithEvent; let l2 = #line
        await assertWTA(
            wta2.node,
            expectedOutput: Self.defaultOutputWithEvent,
            sutLine: l2
        )
    }

    @Test func whenThenActionsAsync_withEvent() async {
        let wta2 = when(1, or: 2) | then(1) | passWithEventAsync; let l2 = #line
        await assertWTA(
            wta2.node,
            expectedOutput: Self.defaultOutputWithEvent,
            sutLine: l2
        )
    }
}
