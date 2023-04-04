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
            "  A: 12"
            "}"
        }, toString(thenNode))
        
        XCTAssertEqual("", actionsOutput)
    }
    
    func testThenNodeWithSingleActionsNodeFileAndLine() {
        XCTAssertEqual(String {
            "T: S1 (null -1) {"
            "  A: 12"
            "}"
        }, toString(thenNode, printFileAndLine: true))
    }
    
    func testThenNodeWithDefaultArgumentAndSingleActionsNode() {
        let t = ThenNode(state: nil, rest: [actionsNode])
        XCTAssertEqual(String {
            "T: default {"
            "  A: 12"
            "}"
        }, toString(t))
    }
    
    func testWhenNodeWithThenAndActionsNodes() {
        XCTAssertEqual(String {
            "W: E1, E2 {"
            "  T: S1 {"
            "    A: 12"
            "  }"
            "}"
        }, toString(whenNode))
    }
    
    func testWhenNodeWithThenAndActionsNodesFileAndLine() {
        XCTAssertEqual(String {
            "W: E1 (null -1), E2 (null -1) {"
            "  T: S1 (null -1) {"
            "    A: 12"
            "  }"
            "}"
        }, toString(whenNode, printFileAndLine: true))
    }
    
    func testGivenNodeWithMatchWhenThenActionsNodes() {
        XCTAssertEqual(String {
            "G: S1, S2 {"
            "  M: any: [[P.a]], all: [Q.a] {"
            "    W: E1, E2 {"
            "      T: S1 {"
            "        A: 12"
            "      }"
            "    }"
            "  }"
            "}"
        }, toString(givenNode(thenState: s1, actionsNode: actionsNode)))
    }
    
    func testGivenNodeWithMatchWhenThenActionsNodesFileAndLine() {
        XCTAssertEqual(String {
            "G: S1 (null -1), S2 (null -1) {"
            "  M: any: [[P.a]], all: [Q.a] (null -1) {"
            "    W: E1 (null -1), E2 (null -1) {"
            "      T: S1 (null -1) {"
            "        A: 12"
            "      }"
            "    }"
            "  }"
            "}"
        }, toString(givenNode(thenState: s1, actionsNode: actionsNode), printFileAndLine: true))
    }
    
    func entry() { onEnterOutput = "entry" }
    func exit()  { onExitOutput = "exit"   }
    
    func testDefineNodeWithGivenMatchWhenThenActions() {
        let d = defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])
        XCTAssertEqual(String {
            "D: entry exit {"
            "  G: S1 {"
            "    M: any: [[P.a]], all: [Q.a] {"
            "      W: E1 {"
            "        T: S2 {"
            "          A: 12"
            "        }"
            "      }"
            "    }"
            "  }"
            "}"
        }, toString(d))
        
        XCTAssertEqual("", onExitOutput)
        XCTAssertEqual("", onEnterOutput)
    }
    
    func testDefineNodeWithGivenMatchWhenThenActionsFileAndLine() {
        let d = defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])
        XCTAssertEqual(String {
            "D: entry exit (null -1) {"
            "  G: S1 (null -1) {"
            "    M: any: [[P.a]], all: [Q.a] (null -1) {"
            "      W: E1 (null -1) {"
            "        T: S2 (null -1) {"
            "          A: 12"
            "        }"
            "      }"
            "    }"
            "  }"
            "}"
        }, toString(d, printFileAndLine: true))
    }
    
    func testThenNodeWithMultipleActionsNodes() {
        let n = ThenNode(state: s1, rest: [actionsNode, actionsNode])
        XCTAssertEqual(String {
            "T: S1 {"
            "  A: 12"
            "  A: 12"
            "}"
        }, toString(n))
    }
    
    func toString(_ n: any NodeBase, printFileAndLine: Bool = false, indent: Int = 0) -> String {
        func string(_ indent: Int) -> String {
            String(repeating: " ", count: indent)
        }
        
        func addRest() {
            if !n._rest.isEmpty {
                output.append(" {\n")
                output.append(n._rest.map {
                    string(indent + 2) + toString($0,
                                                  printFileAndLine: printFileAndLine,
                                                  indent: indent + 2)
                }.joined(separator: "\n"))
                output.append("\n" + string(indent) + "}")
            }
        }
        
        var output = ""
        
        if let n = n as? ActionsNodeBase {
            n.actions.executeAll()
            output.append("A: \(actionsOutput)")
            actionsOutput = ""
        }
        
        if let n = n as? ThenNodeBase {
            if let state = n.state {
                output.append("T: \(n.state!)")
                if printFileAndLine {
                    output.append(" (\(state.file) \(state.line))")
                }
            } else {
                output.append("T: default")
            }
        }
        
        if let n = n as? WhenNodeBase {
            if printFileAndLine {
                let description = n.events.map { $0.description + " (\($0.file) \($0.line))" }
                output.append("W: \(description.joined(separator: ", "))")
            } else {
                output.append("W: \(n.events.map(\.description).joined(separator: ", "))")
            }
        }
        
        if let n = n as? MatchNode {
            output.append("M: any: \(n.match.matchAny), all: \(n.match.matchAll)")
            if printFileAndLine {
                output.append(" (\(n.match.file) \(n.match.line))")
            }
        }
        
        if let n = n as? GivenNode {
            if printFileAndLine {
                let description = n.states.map { $0.description + " (\($0.file) \($0.line))" }
                output.append("G: \(description.joined(separator: ", "))")
            } else {
                output.append("G: \(n.states.map(\.description).joined(separator: ", "))")
            }
        }
        
        if let n = n as? DefineNode {
            n.onEntry.executeAll()
            n.onExit.executeAll()
            output.append("D: \(onEnterOutput) \(onExitOutput)")
            if printFileAndLine {
                output.append(" (\(n.file) \(n.line))")
            }
            onEnterOutput = ""
            onExitOutput = ""
        }
        
        addRest()
        return output
    }
}
