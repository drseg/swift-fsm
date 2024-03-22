import XCTest
@testable import SwiftFSM

class StringableNodeTestTests: StringableNodeTest {
    func assertToString(
        _ expected: String,
        _ actual: any Node,
        fileAndLine: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let actual = await toString(actual, printFileAndLine: fileAndLine)
        XCTAssertEqual(expected,
                       actual,
                       file: file,
                       line: line)
        
        XCTAssertEqual("", actionsOutput, file: file, line: line)
        XCTAssertEqual("", onExitOutput, file: file, line: line)
        XCTAssertEqual("", onEntryOutput, file: file, line: line)
    }

    var entry: AnyAction { AnyAction({ self.onEntryOutput = "entry" }) }
    var exit: AnyAction { AnyAction({ self.onExitOutput = "exit"   }) }

    func testSingleNodeWithNoRest() async {
        await assertToString("A: 12", actionsNode)
    }
    
    func testThenNodeWithSingleActionsNode() async {
        await assertToString(String {
            "T: S1 {"
            "  A: 12"
            "}"
        }, thenNode)
    }
    
    func testThenNodeWithSingleActionsNodeFileAndLine() async {
        await assertToString(String {
            "T: S1 (null -1) {"
            "  A: 12"
            "}"
        }, thenNode, fileAndLine: true)
    }
    
    func testThenNodeWithDefaultArgumentAndSingleActionsNode() async {
        await assertToString(String {
            "T: default {"
            "  A: 12"
            "}"
        }, ThenNode(state: nil, rest: [actionsNode]))
    }
    
    func testWhenNodeWithThenAndActionsNodes() async {
        await assertToString(String {
            "W: E1, E2 {"
            "  T: S1 {"
            "    A: 12"
            "  }"
            "}"
        }, whenNode)
    }
    
    func testWhenNodeWithThenAndActionsNodesFileAndLine() async {
        await assertToString(String {
            "W: E1 (null -1), E2 (null -1) {"
            "  T: S1 (null -1) {"
            "    A: 12"
            "  }"
            "}"
        }, whenNode, fileAndLine: true)
    }
    
    func testGivenNodeWithMatchWhenThenActionsNodes() async {
        await assertToString(String {
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
    
    func testGivenNodeWithMatchWhenThenActionsNodesFileAndLine() async {
        await assertToString(String {
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
    
    func testDefineNodeWithGivenMatchWhenThenActions() async {
        await assertToString(String {
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
    
    func testDefineNodeWithGivenMatchWhenThenActionsFileAndLine() async {
        await assertToString(String {
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
    
    func testActionsResolvingNode() async {
        await assertToString(String {
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
    
    func testSemanticValidationNode() async {
        let a = ActionsResolvingNodeBase(
            rest: [defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])]
        )
        let svn = SemanticValidationNode(rest: [a])
        
        await assertToString(String {
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
    
    func testActionsBlockNodeFileAndLine() async {
        let a = ActionsBlockNode(actions: actions, rest: [], file: "null", line: -1)
        await assertToString("A: 12 (null -1)", a, fileAndLine: true)
    }
    
    func testThenBlockNodeFileAndLine() async {
        let t = ThenBlockNode(state: s1, rest: [], file: "null", line: -1)
        await assertToString("T (null -1): S1 (null -1)", t, fileAndLine: true)
    }
    
    func testWhenBlockNodeFileAndLine() async {
        let w = WhenBlockNode(events: [e1], rest: [], file: "null", line: -1)
        await assertToString("W (null -1): E1 (null -1)", w, fileAndLine: true)
    }
    
    func testMatchBlockNodeFileAndLine() async {
        let w = MatchBlockNode(match: m1, file: "null", line: -1)
        await assertToString("M (null -1): any: [[P.a]], all: [Q.a] (null -1)",
                       w, fileAndLine: true)
    }
    
    func testThenNodeWithMultipleActionsNodes() async {
        await assertToString(String {
            "T: S1 {"
            "  A: 12"
            "  A: 12"
            "}"
        }, ThenNode(state: s1, rest: [actionsNode, actionsNode]))
    }
    
    func testAssertEqual() async throws {
        if Int.random(in: 1...20) == 1 {
            let t1 = ThenNode(state: AnyTraceable("", file: "f", line: 1))
            let t2 = ThenNode(state: AnyTraceable("", file: "f", line: 2))
            let t3 = ThenNode(state: AnyTraceable("", file: "g", line: 1))

            await assertEqual(t1, t1)
            await assertEqualFileAndLine(t1, t1)

            await assertEqual(t1, t2)
            await assertEqual(t1, t3)
            await assertEqual(t2, t3)
            
            let e = expectation(description: "")
            Task {
                XCTExpectFailure()
                await assertEqual(t1, whenNode)
                await assertEqualFileAndLine(t1, whenNode)
                await assertEqualFileAndLine(t1, t2)
                await assertEqualFileAndLine(t1, t3)
                await assertEqualFileAndLine(t2, t3)
                e.fulfill()
            }
            await fulfillment(of: [e])
        } else {
            throw XCTSkip("XCTExpectFailure() is slow, therefore this test runs only occasionally")
        }
    }
}

class StringableNodeTest: DefineConsumer {
    func assertEqual(
        _ lhs: any Node,
        _ rhs: any Node,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let lhs = await toString(lhs)
        let rhs = await toString(rhs)
        XCTAssertEqual(lhs, rhs, file: file, line: line)
    }
    
    func assertEqualFileAndLine(
        _ lhs: any Node,
        _ rhs: any Node,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let lhs = await toString(lhs, printFileAndLine: true)
        let rhs = await toString(rhs, printFileAndLine: true)
        XCTAssertEqual(lhs,
                       rhs,
                       file: file,
                       line: line)
    }
    

    func toString(_ n: some Node, printFileAndLine: Bool = false, indent: Int = 0) async -> String {
        var output = ""

        func string(_ indent: Int) -> String {
            String(repeating: " ", count: indent)
        }

        func addRest() async {
            if !n.rest.isEmpty {
                output.append(" {\n")
                await output.append(n.rest.asyncMap {
                    let rhs = await toString($0,
                                             printFileAndLine: printFileAndLine,
                                             indent: indent + 2)
                    return string(indent + 2) + rhs
                }.joined(separator: "\n"))
                output.append("\n" + string(indent) + "}")
            }
        }

        func fileAndLine(_ file: String, _ line: Int) -> String {
            " (\(file) \(line))"
        }

        func visit(_ n: ActionsNodeBase) async {
            await n.actions.executeAll()
            output.append("A: \(actionsOutput.formatted)")

            if let n = n as? ActionsBlockNode, printFileAndLine {
                output.append(fileAndLine(n.file, n.line))
            }
            actionsOutput = ""
        }

        func visit(_ n: ThenNodeBase) async {
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

        func visit(_ n: WhenNodeBase) async {
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

        func visit(_ n: MatchNodeBase) async  {
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

        func visit(_ n: GivenNode) async {
            if printFileAndLine {
                let description = n.states.map { $0.description + fileAndLine($0.file, $0.line) }
                output.append("G: \(description.joined(separator: ", "))")
            } else {
                output.append("G: \(n.states.map(\.description).joined(separator: ", "))")
            }
        }

        func visit(_ n: DefineNode) async {
            await n.onEntry.executeAll()
            await n.onExit.executeAll()
            output.append("D: entry: \(onEntryOutput.formatted), exit: \(onExitOutput.formatted)")
            if printFileAndLine {
                output.append(fileAndLine(n.file, n.line) )
            }
            onEntryOutput = ""
            onExitOutput = ""
        }

        func visit(_ n: ActionsResolvingNodeBase) async {
            output.append("ARN:")
        }

        func visit(_ n: SemanticValidationNode) async {
            output.append("SVN:")
        }

        switch n {
        case let n as ActionsNodeBase: await visit(n)
        case let n as ThenNodeBase: await visit(n)
        case let n as WhenNodeBase: await visit(n)
        case let n as MatchNodeBase: await visit(n)
        case let n as GivenNode: await visit(n)
        case let n as DefineNode: await visit(n)
        case let n as ActionsResolvingNodeBase: await visit(n)
        case let n as SemanticValidationNode: await visit(n)
        default: break
        }
        
        await addRest()
        return output
    }
}

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

private extension String {
    var formatted: String {
        isEmpty ? "none" : self
    }
}
