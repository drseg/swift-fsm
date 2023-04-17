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
    
    func entry() { onEntryOutput = "entry" }
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
        XCTAssertEqual("", onEntryOutput)
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
    
    func testActionsBlockNodeFileAndLine() {
        let a = ActionsBlockNode(actions: actions, rest: [], file: "null", line: -1)
        XCTAssertEqual("A: 12 (null -1)", toString(a, printFileAndLine: true))
    }
    
    func testThenBlockNodeFileAndLine() {
        let t = ThenBlockNode(state: s1, rest: [], file: "null", line: -1)
        XCTAssertEqual("T (null -1): S1 (null -1)", toString(t, printFileAndLine: true))
    }
    
    func testWhenBlockNodeFileAndLine() {
        let w = WhenBlockNode(events: [e1], rest: [], file: "null", line: -1)
        XCTAssertEqual("W (null -1): E1 (null -1)", toString(w, printFileAndLine: true))
    }
    
    func testMatchBlockNodeFileAndLine() {
        let w = MatchBlockNode(match: m1, file: "null", line: -1)
        XCTAssertEqual("M (null -1): any: [[P.a]], all: [Q.a] (null -1)",
                       toString(w, printFileAndLine: true))
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
        
        func fileAndLine(_ file: String, _ line: Int) -> String {
            " (\(file) \(line))"
        }
        
        var output = ""
        
        if let n = n as? ActionsNodeBase {
            n.actions.executeAll()
            output.append("A: \(actionsOutput)")
            
            if let n = n as? ActionsBlockNode, printFileAndLine {
                output.append(fileAndLine(n.file, n.line))
            }
            actionsOutput = ""
        }
        
        if let n = n as? ThenNodeBase {
            if let state = n.state {
                if let n = n as? ThenBlockNode, printFileAndLine {
                    output.append("T" + fileAndLine(n.file, n.line) + ": \(state)")
                } else {
                    output.append("T: \(state)")
                }
                if printFileAndLine {
                    output.append(fileAndLine(state.file, state.line))
                }
            } else {
                output.append("T: default")
            }
        }
        
        if let n = n as? WhenNodeBase {
            if printFileAndLine {
                let description = n.events.map { $0.description + fileAndLine($0.file, $0.line) }
                
                if let n = n as? WhenBlockNode, printFileAndLine {
                    output.append("W" + fileAndLine(n.file, n.line)
                                  + ": \(description.joined(separator: ", "))")

                } else {
                    output.append("W: \(description.joined(separator: ", "))")
                }
            } else {
                output.append("W: \(n.events.map(\.description).joined(separator: ", "))")
            }
        }
        
        if let n = n as? MatchNodeBase {
            if let n = n as? MatchBlockNode, printFileAndLine {
                output.append("M" + fileAndLine(n.file, n.line)
                              + ": any: \(n.match.matchAny), all: \(n.match.matchAll)")
            } else {
                output.append("M: any: \(n.match.matchAny), all: \(n.match.matchAll)")
            }
            if printFileAndLine {
                output.append(fileAndLine(n.match.file, n.match.line))
            }
        }
        
        if let n = n as? GivenNode {
            if printFileAndLine {
                let description = n.states.map { $0.description + fileAndLine($0.file, $0.line) }
                output.append("G: \(description.joined(separator: ", "))")
            } else {
                output.append("G: \(n.states.map(\.description).joined(separator: ", "))")
            }
        }
        
        if let n = n as? DefineNode {
            n.onEntry.executeAll()
            n.onExit.executeAll()
            output.append("D: \(onEntryOutput) \(onExitOutput)")
            if printFileAndLine {
                output.append(fileAndLine(n.file, n.line) )
            }
            onEntryOutput = ""
            onExitOutput = ""
        }
        
        addRest()
        return output
    }
}
