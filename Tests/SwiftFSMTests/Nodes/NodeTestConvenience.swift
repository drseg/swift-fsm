//
//  NodeTestConvenience.swift
//
//  Created by Daniel Segall on 04/04/2023.
//

import XCTest
@testable import SwiftFSM

class NodeTestConvenience: DefineConsumer {
    func testSingleNodeWithNoRest() {
        XCTAssertEqual("A: 12", toString(actionsNode))
    }
    
    func testThenNodeWithSingleActionsNode() {
        XCTAssertEqual(String {
            "T: S1 {"
            "    A: 12"
            "}"
        }, toString(thenNode))
        
        XCTAssertEqual("", actionsOutput)
    }
    
    func testThenNodeWithDefaultArgumentAndSingleActionsNode() {
        let t = ThenNode(state: nil, rest: [actionsNode])
        XCTAssertEqual(String {
            "T: default {"
            "    A: 12"
            "}"
        }, toString(t))
    }
    
    func testWhenNodeWithThenAndActionsNodes() {
        XCTAssertEqual(String {
            "W: E1, E2 {"
            "    T: S1 {"
            "        A: 12"
            "    }"
            "}"
        }, toString(whenNode))
    }
    
    func testGivenNodeWithMatchWhenThenActionsNodes() {
        XCTAssertEqual(String {
            "G: S1, S2 {"
            "    M: any: [[P.a]], all: [Q.a] {"
            "        W: E1, E2 {"
            "            T: S1 {"
            "                A: 12"
            "            }"
            "        }"
            "    }"
            "}"
        }, toString(givenNode(thenState: s1, actionsNode: actionsNode)))
    }
    
    func testDefineNodeWithGivenMatchWhenThenActions() {
        let entry = { self.onEnterOutput = "entry" }
        let exit =  { self.onExitOutput = "exit"   }
        
        let d = defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])
        XCTAssertEqual(String {
            "D: entry exit {"
            "    G: S1 {"
            "        M: any: [[P.a]], all: [Q.a] {"
            "            W: E1 {"
            "                T: S2 {"
            "                    A: 12"
            "                }"
            "            }"
            "        }"
            "    }"
            "}"
        }, toString(d))
        
        XCTAssertEqual("", onExitOutput)
        XCTAssertEqual("", onEnterOutput)
    }
    
    func testThenNodeWithMultipleActionsNodes() {
        let n = ThenNode(state: s1, rest: [actionsNode, actionsNode])
        XCTAssertEqual(String {
            "T: S1 {"
            "    A: 12"
            "    A: 12"
            "}"
        }, toString(n))
    }
    
    func toString(_ n: any NodeBase, indent: Int = 0) -> String {
        func addRest() {
            if !n._rest.isEmpty {
                let newIndentString = String(repeating: " ", count: indent + 4)
                output.append(" {\n")
                output.append(n._rest.map {
                    newIndentString + toString($0, indent: indent + 4)
                }.joined(separator: "\n"))
                print(indent)
                output.append("\n" + String(repeating: " ", count: indent) + "}")
            }
        }
        
        var output = String(repeating: "", count: indent)
        
        if let n = n as? ActionsNodeBase {
            n.actions.executeAll()
            output.append("A: \(actionsOutput)")
            actionsOutput = ""
        }
        
        if let n = n as? ThenNodeBase {
            if let state = n.state {
                output.append("T: \(state)")
            } else {
                output.append("T: default")
            }
        }
        
        if let n = n as? WhenNodeBase {
            output.append("W: \(n.events.map(\.description).joined(separator: ", "))")
        }
        
        if let n = n as? MatchNode {
            output.append("M: any: \(n.match.matchAny), all: \(n.match.matchAll)")
        }
        
        if let n = n as? GivenNode {
            output.append("G: \(n.states.map(\.description).joined(separator: ", "))")
        }
        
        if let n = n as? DefineNode {
            n.onEntry.executeAll()
            n.onExit.executeAll()
            output.append("D: \(onEnterOutput) \(onExitOutput)")
            onEnterOutput = ""
            onExitOutput = ""
        }
        
        addRest()
        return output
    }
}
