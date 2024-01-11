import XCTest
@testable import SwiftFSM

class StringableNodeTestTests: StringableNodeTest {
    func assertToString(
        _ expected: String,
        _ actual: any NodeBase,
        fileAndLine: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(expected,
                       toString(actual, printFileAndLine: fileAndLine),
                       file: file,
                       line: line)
        
        XCTAssertEqual("", actionsOutput, file: file, line: line)
        XCTAssertEqual("", onExitOutput, file: file, line: line)
        XCTAssertEqual("", onEntryOutput, file: file, line: line)
    }

    var entry: AnyAction { AnyAction({ self.onEntryOutput = "entry" }) }
    var exit: AnyAction { AnyAction({ self.onExitOutput = "exit"   }) }

    func testSingleNodeWithNoRest() {
        assertToString("A: 12", actionsNode)
    }
    
    func testThenNodeWithSingleActionsNode() {
        assertToString(String {
            "T: S1 {"
            "  A: 12"
            "}"
        }, thenNode)
    }
    
    func testThenNodeWithSingleActionsNodeFileAndLine() {
        assertToString(String {
            "T: S1 (null -1) {"
            "  A: 12"
            "}"
        }, thenNode, fileAndLine: true)
    }
    
    func testThenNodeWithDefaultArgumentAndSingleActionsNode() {
        assertToString(String {
            "T: default {"
            "  A: 12"
            "}"
        }, ThenNode(state: nil, rest: [actionsNode]))
    }
    
    func testWhenNodeWithThenAndActionsNodes() {
        assertToString(String {
            "W: E1, E2 {"
            "  T: S1 {"
            "    A: 12"
            "  }"
            "}"
        }, whenNode)
    }
    
    func testWhenNodeWithThenAndActionsNodesFileAndLine() {
        assertToString(String {
            "W: E1 (null -1), E2 (null -1) {"
            "  T: S1 (null -1) {"
            "    A: 12"
            "  }"
            "}"
        }, whenNode, fileAndLine: true)
    }
    
    func testGivenNodeWithMatchWhenThenActionsNodes() {
        assertToString(String {
            "G: S1, S2 {"
            "  M: any: [[P.a]], all: [Q.a] {"
            "    W: E1, E2 {"
            "      T: S1 {"
            "        A: 12"
            "      }"
            "    }"
            "  }"
            "}"
        }, givenNode(thenState: s1, actionsNode: actionsNode))
    }
    
    func testGivenNodeWithMatchWhenThenActionsNodesFileAndLine() {
        assertToString(String {
            "G: S1 (null -1), S2 (null -1) {"
            "  M: any: [[P.a]], all: [Q.a] (null -1) {"
            "    W: E1 (null -1), E2 (null -1) {"
            "      T: S1 (null -1) {"
            "        A: 12"
            "      }"
            "    }"
            "  }"
            "}"
        }, givenNode(thenState: s1, actionsNode: actionsNode), fileAndLine: true)
    }
    
    func testDefineNodeWithGivenMatchWhenThenActions() {
        assertToString(String {
            "D: entry: entry, exit: exit {"
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
        }, defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit]))
    }
    
    func testDefineNodeWithGivenMatchWhenThenActionsFileAndLine() {
        assertToString(String {
            "D: entry: entry, exit: exit (null -1) {"
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
        }, defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit]), fileAndLine: true)
    }
    
    func testActionsResolvingNode() {
        assertToString(String {
            "ARN: {"
            "  D: entry: entry, exit: exit {"
            "    G: S1 {"
            "      M: any: [[P.a]], all: [Q.a] {"
            "        W: E1 {"
            "          T: S2 {"
            "            A: 12"
            "          }"
            "        }"
            "      }"
            "    }"
            "  }"
            "}"
        }, ActionsResolvingNodeBase(
            rest: [defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])])
        )
    }
    
    func testSemanticValidationNode() {
        let a = ActionsResolvingNodeBase(
            rest: [defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])]
        )
        let svn = SemanticValidationNode(rest: [a])
        
        assertToString(String {
            "SVN: {"
            "  ARN: {"
            "    D: entry: entry, exit: exit {"
            "      G: S1 {"
            "        M: any: [[P.a]], all: [Q.a] {"
            "          W: E1 {"
            "            T: S2 {"
            "              A: 12"
            "            }"
            "          }"
            "        }"
            "      }"
            "    }"
            "  }"
            "}"
        }, svn)
    }
    
    func testActionsBlockNodeFileAndLine() {
        let a = ActionsBlockNode(actions: actions, rest: [], file: "null", line: -1)
        assertToString("A: 12 (null -1)", a, fileAndLine: true)
    }
    
    func testThenBlockNodeFileAndLine() {
        let t = ThenBlockNode(state: s1, rest: [], file: "null", line: -1)
        assertToString("T (null -1): S1 (null -1)", t, fileAndLine: true)
    }
    
    func testWhenBlockNodeFileAndLine() {
        let w = WhenBlockNode(events: [e1], rest: [], file: "null", line: -1)
        assertToString("W (null -1): E1 (null -1)", w, fileAndLine: true)
    }
    
    func testMatchBlockNodeFileAndLine() {
        let w = MatchBlockNode(match: m1, file: "null", line: -1)
        assertToString("M (null -1): any: [[P.a]], all: [Q.a] (null -1)",
                       w, fileAndLine: true)
    }
    
    func testThenNodeWithMultipleActionsNodes() {
        assertToString(String {
            "T: S1 {"
            "  A: 12"
            "  A: 12"
            "}"
        }, ThenNode(state: s1, rest: [actionsNode, actionsNode]))
    }
    
    func testAssertEqual() {
        let t1 = ThenNode(state: AnyTraceable("", file: "f", line: 1))
        let t2 = ThenNode(state: AnyTraceable("", file: "f", line: 2))
        let t3 = ThenNode(state: AnyTraceable("", file: "g", line: 1))
        
        assertEqual(t1, t1)
        assertEqualFileAndLine(t1, t1)
        
        assertEqual(t1, t2)
        assertEqual(t1, t3)
        assertEqual(t2, t3)
        
        XCTExpectFailure {
            assertEqual(t1, whenNode)
            assertEqualFileAndLine(t1, whenNode)

            assertEqualFileAndLine(t1, t2)
            assertEqualFileAndLine(t1, t3)
            assertEqualFileAndLine(t2, t3)
        }
    }
}

class StringableNodeTest: DefineConsumer {
    func assertEqual(
        _ lhs: any NodeBase,
        _ rhs: any NodeBase,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(toString(lhs), toString(rhs), file: file, line: line)
    }
    
    func assertEqualFileAndLine(
        _ lhs: any NodeBase,
        _ rhs: any NodeBase,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(toString(lhs, printFileAndLine: true),
                       toString(rhs, printFileAndLine: true),
                       file: file,
                       line: line)
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
            output.append("A: \(actionsOutput.formatted)")
            
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
            output.append("D: entry: \(onEntryOutput.formatted), exit: \(onExitOutput.formatted)")
            if printFileAndLine {
                output.append(fileAndLine(n.file, n.line) )
            }
            onEntryOutput = ""
            onExitOutput = ""
        }
        
        if n is ActionsResolvingNodeBase {
            output.append("ARN:")
        }
        
        if n is SemanticValidationNode {
            output.append("SVN:")
        }
        
        addRest()
        return output
    }
}

private extension String {
    var formatted: String {
        self == "" ? "none" : self
    }
}
