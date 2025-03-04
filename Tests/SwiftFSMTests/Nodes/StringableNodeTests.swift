import Testing
@testable import SwiftFSM

class StringableNodeTestTests: StringableNodeTest {
    func assertToString(
        _ expected: String,
        _ actual: any SyntaxNode,
        fileAndLine: Bool = false,
        location: SourceLocation = #_sourceLocation
    ) async {
        let actual = await toString(actual, printFileAndLine: fileAndLine)
        #expect(expected == actual, sourceLocation: location)
        
        #expect("" == actionsOutput, sourceLocation: location)
        #expect("" == onExitOutput, sourceLocation: location)
        #expect("" == onEntryOutput, sourceLocation: location)
    }

    var entry: AnyAction { AnyAction({ self.onEntryOutput = "entry" }) }
    var exit: AnyAction { AnyAction({ self.onExitOutput = "exit"   }) }

    @Test func singleNodeWithNoRest() async {
        await assertToString("A: 12", actionsNode)
    }
    
    @Test func thenNodeWithSingleActionsNode() async {
        await assertToString(String {
            "T: S1 {"
            "  A: 12"
            "}"
        }, thenNode)
    }
    
    @Test func thenNodeWithSingleActionsNodeFileAndLine() async {
        await assertToString(String {
            "T: S1 (null -1) {"
            "  A: 12"
            "}"
        }, thenNode, fileAndLine: true)
    }
    
    @Test func thenNodeWithDefaultArgumentAndSingleActionsNode() async {
        await assertToString(String {
            "T: default {"
            "  A: 12"
            "}"
        }, ThenNode(state: nil, rest: [actionsNode]))
    }
    
    @Test func whenNodeWithThenAndActionsNodes() async {
        await assertToString(String {
            "W: E1, E2 {"
            "  T: S1 {"
            "    A: 12"
            "  }"
            "}"
        }, whenNode)
    }
    
    @Test func whenNodeWithThenAndActionsNodesFileAndLine() async {
        await assertToString(String {
            "W: E1 (null -1), E2 (null -1) {"
            "  T: S1 (null -1) {"
            "    A: 12"
            "  }"
            "}"
        }, whenNode, fileAndLine: true)
    }
    
    @Test func givenNodeWithMatchWhenThenActionsNodes() async {
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
    
    @Test func givenNodeWithMatchWhenThenActionsNodesFileAndLine() async {
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
    
    @Test func defineNodeWithGivenMatchWhenThenActions() async {
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
    
    @Test func defineNodeWithGivenMatchWhenThenActionsFileAndLine() async {
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
    
    @Test func actionsResolvingNode() async {
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
        }, ActionsResolvingNode(
            rest: [defineNode(s1, m1, e1, s2, entry: [entry], exit: [exit])])
        )
    }
    
    @Test func semanticValidationNode() async {
        let a = ActionsResolvingNode(
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
    
    @Test func actionsBlockNodeFileAndLine() async {
        let a = ActionsBlockNode(actions: actions, rest: [], file: "null", line: -1)
        await assertToString("A: 12 (null -1)", a, fileAndLine: true)
    }
    
    @Test func thenBlockNodeFileAndLine() async {
        let t = ThenBlockNode(state: s1, rest: [], file: "null", line: -1)
        await assertToString("T (null -1): S1 (null -1)", t, fileAndLine: true)
    }
    
    @Test func whenBlockNodeFileAndLine() async {
        let w = WhenBlockNode(events: [e1], rest: [], file: "null", line: -1)
        await assertToString("W (null -1): E1 (null -1)", w, fileAndLine: true)
    }
    
    @Test func matchBlockNodeFileAndLine() async {
        let w = MatchingBlockNode(descriptor: m1, file: "null", line: -1)
        await assertToString("M (null -1): any: [[P.a]], all: [Q.a] (null -1)",
                       w, fileAndLine: true)
    }
    
    @Test func thenNodeWithMultipleActionsNodes() async {
        await assertToString(String {
            "T: S1 {"
            "  A: 12"
            "  A: 12"
            "}"
        }, ThenNode(state: s1, rest: [actionsNode, actionsNode]))
    }
    
    let t1 = ThenNode(state: AnyTraceable("", file: "f", line: 1))
    let t2 = ThenNode(state: AnyTraceable("", file: "f", line: 2))
    let t3 = ThenNode(state: AnyTraceable("", file: "g", line: 1))
    
    @Test func assertEqualPass() async throws {
        await assertEqual(t1, t1)
        await assertEqual(t1, t2)
        await assertEqual(t1, t3)
        await assertEqual(t2, t3)
        await assertEqualFileAndLine(t1, t1)
    }
    
    @Test func assertEqualFail() async throws {
        await withKnownIssue("These are meant to fail") {
            await assertEqual(t1, whenNode)
            await assertEqualFileAndLine(t1, whenNode)
            await assertEqualFileAndLine(t1, t2)
            await assertEqualFileAndLine(t1, t3)
            await assertEqualFileAndLine(t2, t3)
        }
    }
}

class StringableNodeTest: DefineConsumer {
    func assertEqual(
        _ lhs: any SyntaxNode,
        _ rhs: any SyntaxNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        let lhs = await toString(lhs)
        let rhs = await toString(rhs)
        #expect(lhs == rhs, sourceLocation: location)
    }
    
    func assertEqualFileAndLine(
        _ lhs: any SyntaxNode,
        _ rhs: any SyntaxNode,
        location: SourceLocation = #_sourceLocation
    ) async {
        let lhs = await toString(lhs, printFileAndLine: true)
        let rhs = await toString(rhs, printFileAndLine: true)
        #expect(lhs == rhs, sourceLocation: location)
    }

    func toString(
        _ n: some SyntaxNode,
        printFileAndLine: Bool = false,
        indent: Int = 0
    ) async -> String {
        var output = ""
        
        switch n {
        case let n as ActionsNodeBase:
            await visit(n, &output, printFileAndLine)
        case let n as ThenNodeBase:
            await visit(n, &output, printFileAndLine)
        case let n as WhenNodeBase:
            await visit(n, &output, printFileAndLine)
        case let n as MatchingNodeBase:
            await visit(n, &output, printFileAndLine)
        case let n as GivenNode:
            await visit(n, &output, printFileAndLine)
        case let n as DefineNode:
            await visit(n, &output, printFileAndLine)
        case let n as ActionsResolvingNode:
            await visit(n, &output, printFileAndLine)
        case let n as SemanticValidationNode:
            await visit(n, &output, printFileAndLine)
        default: break
        }

        await addRest(n, &output, printFileAndLine, indent)
        return output
    }

    private func visit(
        _ n: ActionsNodeBase,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
        await n.actions.executeAll()
        output.append("A: \(actionsOutput.formatted)")

        if let n = n as? ActionsBlockNode, printFileAndLine {
            output.append(fileAndLine(n.file, n.line))
        }
        actionsOutput = ""
    }

    private func visit(
        _ n: ThenNodeBase,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
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

    private func visit(
        _ n: WhenNodeBase,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
        if printFileAndLine {
            let description = n.events.map { $0.description + fileAndLine($0.file, $0.line) }

            if let n = n as? WhenBlockNode, printFileAndLine {
                output.append(
                    "W" + fileAndLine(n.file, n.line)
                    + ": \(description.joined(separator: ", "))"
                )

            } else {
                output.append("W: \(description.joined(separator: ", "))")
            }
        } else {
            output.append("W: \(n.events.map(\.description).joined(separator: ", "))")
        }
    }

    private func visit(
        _ n: MatchingNodeBase,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async  {
        if let n = n as? MatchingBlockNode, printFileAndLine {
            output.append(
                "M" + fileAndLine(n.file, n.line) +
                ": any: \(n.descriptor.matchingAny), all: \(n.descriptor.matchingAll)"
            )
        } else {
            output.append(
                "M: any: \(n.descriptor.matchingAny), all: \(n.descriptor.matchingAll)"
            )
        }
        if printFileAndLine {
            output.append(fileAndLine(n.descriptor.file, n.descriptor.line))
        }
    }

    private func visit(
        _ n: GivenNode,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
        if printFileAndLine {
            let description = n.states.map { $0.description + fileAndLine($0.file, $0.line) }
            output.append(
                "G: \(description.joined(separator: ", "))"
            )
        } else {
            output.append(
                "G: \(n.states.map(\.description).joined(separator: ", "))"
            )
        }
    }

    private func visit(
        _ n: DefineNode,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
        await n.onEntry.executeAll()
        await n.onExit.executeAll()
        output.append(
            "D: entry: \(onEntryOutput.formatted), exit: \(onExitOutput.formatted)"
        )
        if printFileAndLine {
            output.append(fileAndLine(n.file, n.line) )
        }
        onEntryOutput = ""
        onExitOutput = ""
    }

    private func visit(
        _ n: ActionsResolvingNode,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
        output.append("ARN:")
    }

    private func visit(
        _ n: SemanticValidationNode,
        _ output: inout String,
        _ printFileAndLine: Bool
    ) async {
        output.append("SVN:")
    }

    private func addRest(
        _ n: some SyntaxNode,
        _ output: inout String,
        _ printFileAndLine: Bool,
        _ indent: Int
    ) async {
        func string(_ indent: Int) -> String {
            String(repeating: " ", count: indent)
        }

        if !n.rest.isEmpty {
            output.append(" {\n")
            await output.append(
                n.rest.asyncMap {
                    let rhs = await toString(
                        $0,
                        printFileAndLine: printFileAndLine,
                        indent: indent + 2
                    )
                return string(indent + 2) + rhs
            }.joined(separator: "\n"))
            output.append("\n" + string(indent) + "}")
        }
    }

    private func fileAndLine(_ file: String, _ line: Int) -> String {
        " (\(file) \(line))"
    }
}

extension Sequence {
    func asyncMap<T: Sendable>(
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
