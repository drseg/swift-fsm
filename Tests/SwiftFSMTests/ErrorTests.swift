import XCTest
@testable import SwiftFSM

typealias EMRN = EagerMatchResolvingNode

final class ErrorTests: SyntaxNodeTests {
    var e: Error!
    
    func testFileName() {
        XCTAssertEqual("", "".name)
        XCTAssertEqual("test", "test".name)
        XCTAssertEqual("test", "/test".name)
        XCTAssertEqual("test", "// ///test".name)
    }
    
    func testSwiftFSMError() {
        e = SwiftFSMError(errors: ["Error1", "Error2"])
        let message = String {
            ""
            "- SwiftFSM Errors -"
            ""
            "2 errors were found:"
            ""
            "Error1"
            "Error2"
            ""
            "- End -"
        }

        e.assertDescription(message)
        XCTAssertEqual((e as CustomStringConvertible).description, message)
    }

    func testEmptyBlockError() {
        e = EmptyBuilderError(caller: "caller", file: "/testfile", line: 10)
        e.assertDescription(
            "Empty @resultBuilder block passed to 'caller' in testfile at line 10"
        )
    }
    
    func testDuplicateMatchTypes() {
        e = DuplicateMatchTypes(predicates: [P.a, P.b].erased(),
                                files: ["/f1"],
                                lines: [1])
        e.assertDescription(
            String {
                "'matching(P.a AND P.b)' is ambiguous - type P appears multiple times"
                "This combination was found in a 'matching' statement at file f1, line 1"
            }
        )
    }
    
    func testDuplicateMatchTypesThroughAddition() {
        e = DuplicateMatchTypes(predicates: [P.a, P.b, Q.a, Q.b].erased(),
                                files: ["/f1", "/f2"],
                                lines: [1, 2])
        e.assertDescription(
            String {
                let preds = "'matching(P.a AND P.b AND Q.a AND Q.b)'"
                "\(preds) is ambiguous - types P, Q appear multiple times"
                "This combination was formed by AND-ing 'matching' statements at:"
                "file f1, line 1"
                "file f2, line 2"
            }
        )
    }
    
    func testDuplicateMatchValues() {
        e = DuplicateAnyValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                               files: ["/f1"],
                               lines: [1])
        e.assertDescription(
            String {
                "'matching(P.a OR P.a OR P.b OR P.b)' contains multiple instances of P.a, P.b"
                "This combination was found in a 'matching' statement at file f1, line 1"
            }
        )
    }
    
    func testDuplicateMatchValuesThroughAddition() {
        e = DuplicateAnyValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                               files: ["/f1", "/f2"],
                               lines: [1, 2])
        e.assertDescription(
            String {
                "'matching(P.a OR P.a OR P.b OR P.b)' contains multiple instances of P.a, P.b"
                "This combination was formed by AND-ing 'matching' statements at:"
                "file f1, line 1"
                "file f2, line 2"
            }
        )
    }
    
    func testDuplicateMatchAnyAllValues() {
        e = DuplicateAnyAllValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                                  files: ["/f1"],
                                  lines: [1])
        e.assertDescription(
            "'matching' statement at file f1, line 1 contains multiple instances of P.a, P.b"
        )
    }
    
    func testDuplicateMatchAnyAllValuesThroughAddition() {
        e = DuplicateAnyAllValues(predicates: [P.a, P.a, P.b, P.b].erased(),
                                  files: ["/f1", "/f2"],
                                  lines: [1, 2])
        e.assertDescription(
            String {
                "When combined, 'matching' statements at:"
                "file f1, line 1"
                "file f2, line 2"
                "...contain multiple instances of P.a, P.b"
            }
        )
    }
    
    func testConflictingMatchAnyvalues() {
        e = ConflictingAnyTypes(predicates: [P.a, R.a].erased(),
                                files: ["/f1"],
                                lines: [1])
        
        e.assertDescription(
            String {
                "'matching(P.a OR R.a)' is ambiguous - 'OR' values must be the same type"
                "This combination was found in a 'matching' statement at file f1, line 1"
            }
        )
    }
    
    func testEmptyTableError() {
        e = EmptyTableError()
        e.assertDescription(
            "FSM tables must have at least one 'define' statement in them"
        )
    }
    
    func testTableAlreadyBuiltError() {
        e = TableAlreadyBuiltError(file: "/f", line: 1)
        e.assertDescription("Duplicate call to method buildTable in file f at line 1")
    }
    
    func testSingleMatchAsArray() {
        let array = try? MatchDescriptorChain(any: P.a).resolve().get() .asArray
        XCTAssertEqual(array, [MatchDescriptorChain(any: P.a)])
    }
    
    func testMultipleMatchesAsArray() {
        let array = try? MatchDescriptorChain(any: P.a)
            .prepend(MatchDescriptorChain(any: R.a))
            .prepend(MatchDescriptorChain())
            .resolve()
            .get()
            .asArray
        
        XCTAssertEqual(array, [MatchDescriptorChain(), MatchDescriptorChain(any: R.a), MatchDescriptorChain(any: P.a)])
    }
    
    func testMatchDescriptionWithCondition() {
        let match = MatchDescriptorChain(condition: { true }, file: "/f", line: 1)
        
        XCTAssertEqual("condition(() -> Bool) @f: 1",
                       match.errorDescription)
    }
    
    func testMatchDescriptionWithNoPredicates() {
        let match = MatchDescriptorChain(file: "f", line: 1)
        
        XCTAssertEqual("matching()",
                       match.errorDescription)
    }
    
    func testMatchDescriptionWithOrOnly() {
        let match = MatchDescriptorChain(any: [[P.a, P.b]], file: "/f", line: 1)
        
        XCTAssertEqual("matching((P.a OR P.b)) @f: 1",
                       match.errorDescription)
    }
    
    func testMatchDescriptionWithMultipleOrOnly() {
        let match = MatchDescriptorChain(any: [[P.a, P.b], [Q.a, Q.b]], file: "/f", line: 1)
        
        XCTAssertEqual("matching((P.a OR P.b) AND (Q.a OR Q.b)) @f: 1",
                       match.errorDescription)
    }
    
    func testMatchDescriptionWithAndOnly() {
        let match = MatchDescriptorChain(all: R.a, S.a, file: "/f", line: 1)
        
        XCTAssertEqual("matching(R.a AND S.a) @f: 1",
                       match.errorDescription)
    }
    
    func testMatchDescriptionWithOrAndAnd() {
        let match = MatchDescriptorChain(any: [[P.a, P.b]], all: R.a, S.a, file: "/f", line: 1)
        
        XCTAssertEqual("matching((P.a OR P.b) AND R.a AND S.a) @f: 1",
                       match.errorDescription)
    }
    
    func testMatchDescriptionWithNext() {
        let match = try? MatchDescriptorChain(any: [[Q.a, Q.b]], file: "/2", line: 2)
            .prepend(MatchDescriptorChain(any: [[P.a, P.b]], all: R.a, S.a, file: "/1", line: 1))
            .resolve()
            .get()

        XCTAssertEqual(String {
            "matching((P.a OR P.b) AND (Q.a OR Q.b) AND R.a AND S.a)"
            "  formed by combining:"
            "    - matching((P.a OR P.b) AND R.a AND S.a) @1: 1"
            "    - matching((Q.a OR Q.b)) @2: 2"
        },
                       match?.errorDescription)
    }
    
    typealias SVN = SemanticValidationNode
    
    func s1(_ line: Int) -> AnyTraceable { AnyTraceable("s1", file: "/fs", line: line) }
    func m1(_ line: Int) -> MatchDescriptorChain { MatchDescriptorChain(any: P.a, all: Q.a, R.a, file: "/fm", line: line) }
    func e1(_ line: Int) -> AnyTraceable { AnyTraceable("e1", file: "/fe", line: line) }
    func s2(_ line: Int) -> AnyTraceable { AnyTraceable("s2", file: "/fns", line: line) }
    
    func testSVNDuplicatesError() {
        let k1 = SVN.DuplicatesKey(OverrideSyntaxDTO(s1(0), m1(0), e1(0), s2(0), []))
        let k2 = SVN.DuplicatesKey(OverrideSyntaxDTO(s2(0), m1(0), e1(0), s2(0), []))

        let values: [SVN.Input] = [OverrideSyntaxDTO(s1(1), m1(2), e1(3), s2(4), []),
                                   OverrideSyntaxDTO(s1(5), m1(6), e1(7), s2(8), [])]
        let duplicates = [k1: values, k2: values]
        
        e = SVN.DuplicatesError(duplicates: duplicates)
        e.assertDescription(
            String {
                "The FSM table contains duplicate groups (total: 2):"
                ""
                "Group 1:"
                ""
                "define(s1) @fs: 1"
                "matching(P.a AND Q.a AND R.a) @fm: 2"
                "when(e1) @fe: 3"
                "then(s2) @fns: 4"
                ""
                "define(s1) @fs: 5"
                "matching(P.a AND Q.a AND R.a) @fm: 6"
                "when(e1) @fe: 7"
                "then(s2) @fns: 8"
                ""
                "Group 2:"
                ""
                "define(s1) @fs: 1"
                "matching(P.a AND Q.a AND R.a) @fm: 2"
                "when(e1) @fe: 3"
                "then(s2) @fns: 4"
                ""
                "define(s1) @fs: 5"
                "matching(P.a AND Q.a AND R.a) @fm: 6"
                "when(e1) @fe: 7"
                "then(s2) @fns: 8"
            }
        )
    }
    
    func testSVNClashesError() {
        let k1 = SVN.ClashesKey(OverrideSyntaxDTO(s1(0), m1(0), e1(0), s2(0), []))
        let k2 = SVN.ClashesKey(OverrideSyntaxDTO(s2(0), m1(0), e1(0), s2(0), []))

        let values: [SVN.Input] = [OverrideSyntaxDTO(s1(1), m1(2), e1(3), s2(4), []),
                                   OverrideSyntaxDTO(s2(5), m1(6), e1(7), s2(8), [])]
        let clashes = [k1: values, k2: values]
        
        e = SVN.ClashError(clashes: clashes)
        e.assertDescription(
            String {
                "The FSM table contains logical clash groups (total: 2):"
                ""
                "Group 1:"
                ""
                "define(s1) @fs: 1"
                "matching(P.a AND Q.a AND R.a) @fm: 2"
                "when(e1) @fe: 3"
                ""
                "define(s2) @fns: 5"
                "matching(P.a AND Q.a AND R.a) @fm: 6"
                "when(e1) @fe: 7"
                ""
                "Group 2:"
                ""
                "define(s1) @fs: 1"
                "matching(P.a AND Q.a AND R.a) @fm: 2"
                "when(e1) @fe: 3"
                ""
                "define(s2) @fns: 5"
                "matching(P.a AND Q.a AND R.a) @fm: 6"
                "when(e1) @fe: 7"
            }
        )
    }
    
    func testSVNNothingToOverrideError() {
        let m = MatchDescriptorChain(all: P.a, file: "/fm", line: 2)
        let override = OverrideSyntaxDTO(s1(1), m, e1(3), s2(4), [], testGroupID, true)
        e = SVN.NothingToOverride(override)
        e.assertDescription(
            String {
                "Nothing To Override: the statement..."
                ""
                "define(s1) @fs: 1 {"
                "   overriding {"
                "       matching(P.a) @fm: 2"
                "       when(e1) @fe: 3"
                "       then(s2) @fns: 4"
                "   }"
                "}"
                ""
                "...does not override anything"
            }
        )
    }
    
    func testSVNOutOfOrderOverrideError() {
        let m = MatchDescriptorChain(all: P.a, file: "/fm", line: 2)
        let override = OverrideSyntaxDTO(s1(1), m, e1(3), s2(4), [], testGroupID, true)
        e = SVN.OverrideOutOfOrder(override, [override, override])
        e.assertDescription(
            String {
                "Overrides Out of Order: SuperState statement..."
                ""
                "define(s1) @fs: 1 {"
                "   overriding {"
                "       matching(P.a) @fm: 2"
                "       when(e1) @fe: 3"
                "       then(s2) @fns: 4"
                "   }"
                "}"
                ""
                "...is attempting to override the following child statements:"
                ""
                "define(s1) @fs: 1 {"
                "   overriding {"
                "       matching(P.a) @fm: 2"
                "       when(e1) @fe: 3"
                "       then(s2) @fns: 4"
                "   }"
                "}"
                ""
                "define(s1) @fs: 1 {"
                "   overriding {"
                "       matching(P.a) @fm: 2"
                "       when(e1) @fe: 3"
                "       then(s2) @fns: 4"
                "   }"
                "}"
            }
        )
    }

    func testMRNClashesError() {
        let m1 = MatchDescriptorChain(any: P.a, file: "/fm", line: 2)
        let m2 = MatchDescriptorChain(any: Q.a, file: "/fm", line: 6)
        
        let pr1 = Set([P.a.erased(), Q.a.erased()])
        let pr2 = Set([R.a.erased(), S.a.erased()])
        
        let k1 = EMRN.ImplicitClashesKey(s1(-1), pr1, e1(0))
        let k2 = EMRN.ImplicitClashesKey(s2(0), pr2, e1(0))
        
        let values = [EMRN.ErrorOutput(s1(1), m1, e1(3), s2(4)),
                      EMRN.ErrorOutput(s1(5), m2, e1(7), s2(8))]
        let clashes = [k1: values, k2: values]
        
        e = EMRN.ImplicitClashesError(clashes: clashes)
        e.assertDescription(
            String {
                "The FSM table contains implicit logical clashes (total: 2)"
                ""
                "Multiple clashing statements imply the same predicates (P.a AND Q.a)"
                ""
                "Context 1:"
                ""
                "define(s1) @fs: 1"
                "matching(P.a) @fm: 2"
                "when(e1) @fe: 3"
                "then(s2) @fns: 4"
                ""
                "define(s1) @fs: 5"
                "matching(Q.a) @fm: 6"
                "when(e1) @fe: 7"
                "then(s2) @fns: 8"
                ""
                "Multiple clashing statements imply the same predicates (R.a AND S.a)"
                ""
                "Context 2:"
                ""
                "define(s1) @fs: 1"
                "matching(P.a) @fm: 2"
                "when(e1) @fe: 3"
                "then(s2) @fns: 4"
                ""
                "define(s1) @fs: 5"
                "matching(Q.a) @fm: 6"
                "when(e1) @fe: 7"
                "then(s2) @fns: 8"
            }
        )
    }
}

extension Error {
    func assertDescription(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(expected, localizedDescription, file: file, line: line)
    }
}
