import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftFSMMacros
import SwiftFSMMacrosEvent
@testable import SwiftFSM

let testMacros: [String: Macro.Type] = [
    "letEvents": StaticLetEventMacro.self,
    "letEventsWithValue": StaticLetEventWithValueMacro.self,
    "funcEvents": StaticFuncEventMacro.self,
    "funcEventsWithValue": StaticFuncEventWithValueMacro.self
]

enum Event {
    /// Cannot add functions to classes using macros (Swift bug)
    /// Adding here in this extension as workaround
    /// https://github.com/apple/swift/issues/68704

    #funcEvents("first", "second")
    #funcEventsWithValue("third", "fourth")
}

final class StaticFuncEventTests: XCTestCase {
    func testEventExpansion() {
        assertMacroExpansion(
            """
            #funcEvents("first", "second")
            """,
            expandedSource:
            """
            static func first() -> FSMEvent<String> {
                FSMEvent<String>(name: "first")
            }
            static func second() -> FSMEvent<String> {
                FSMEvent<String>(name: "second")
            }
            """,
            macros: testMacros)
    }

    func testEventExpansionOnlyAllowsStringLiterals() throws {
        assertMacroExpansion(
            "#funcEvents(first)",
            expandedSource: "#funcEvents(first)",
            diagnostics: [.init("Event names must be String literals")],
            macros: testMacros
        )
    }

    func testLiveEventMacro() throws {
        XCTAssertEqual(Event.first().name, "first")
        XCTAssertEqual(Event.first().value, nil)

        XCTAssertEqual(Event.second().name, "second")
        XCTAssertEqual(Event.second().value, nil)
    }

    func testEventWithValueExpansion() throws {
        assertMacroExpansion(
            """
            #funcEventsWithValue("third", "fourth")
            """,
            expandedSource:
            """
            static func third<T: Hashable>(_ value: FSMValue<T> = .any) -> FSMEvent<T> {
                FSMEvent<T>(value, name: "third")
            }
            static func third<T: Hashable>(_ value: T) -> FSMEvent<T> {
                FSMEvent<T>(FSMValue<T>.some(value), name: "third")
            }
            static func fourth<T: Hashable>(_ value: FSMValue<T> = .any) -> FSMEvent<T> {
                FSMEvent<T>(value, name: "fourth")
            }
            static func fourth<T: Hashable>(_ value: T) -> FSMEvent<T> {
                FSMEvent<T>(FSMValue<T>.some(value), name: "fourth")
            }
            """,
            macros: testMacros)
    }

//    func testLiveEventWithValueMacro() throws {
//        XCTAssertEqual(Event.third(.any).value, nil)
//    }
}

final class StaticLetEventTests: XCTestCase {
    #letEvent("robin")
    #letEvents("cat", "fish")

    #letEventWithValue("jay")
    #letEventsWithValue("dog", "llama")

    static func event(_ s: String) -> String { s }
    static func eventWithValue(_ s: String) -> String { s }

    func testEventExpansion() throws {
        assertMacroExpansion(
            """
            #letEvents("first", "second", "third", "fourth")
            """,
            expandedSource: """
            static let first = event("first")
            static let second = event("second")
            static let third = event("third")
            static let fourth = event("fourth")
            """,
            macros: testMacros
        )
    }

    func testEventExpansionOnlyAllowsStringLiterals() throws {
        assertMacroExpansion(
            "#letEvents(first)",
            expandedSource: "#letEvents(first)",
            diagnostics: [.init("Event names must be String literals")],
            macros: testMacros
        )
    }

    func testEventsMacro() throws {
        XCTAssertEqual(Self.cat, "cat")
        XCTAssertEqual(Self.fish, "fish")
    }

    func testEventsWithValueExpansion() throws {
        assertMacroExpansion(
            """
            #letEventsWithValue("first", "second", "third", "fourth")
            """,
            expandedSource: """
            static let first = eventWithValue("first")
            static let second = eventWithValue("second")
            static let third = eventWithValue("third")
            static let fourth = eventWithValue("fourth")
            """,
            macros: testMacros
        )
    }

    func testEventsWithValueExpansionOnlyAllowsStringLiterals() throws {
        assertMacroExpansion(
            "#letEventsWithValue(first)",
            expandedSource: "#letEventsWithValue(first)",
            diagnostics: [.init("Event names must be String literals")],
            macros: testMacros
        )
    }

    func testEventsVariadThrowsWithNoArguments() {
        assertMacroExpansion(
            "#letEvents()",
            expandedSource: "#letEvents()",
            diagnostics: [.init("Must include at least one String literal argument")],
            macros: testMacros
        )
    }

    func testEventsWithValueVariadThrowsWithNoArguments() {
        assertMacroExpansion(
            "#letEventsWithValue()",
            expandedSource: "#letEventsWithValue()",
            diagnostics: [.init("Must include at least one String literal argument")],
            macros: testMacros
        )
    }

    func testEventsWithValueMacro() throws {
        XCTAssertEqual(Self.dog, "dog")
        XCTAssertEqual(Self.llama, "llama")
    }

    func testSingularMacros() throws {
        XCTAssertEqual(Self.robin, "robin")
        XCTAssertEqual(Self.jay, "jay")
    }
}

extension DiagnosticSpec {
    init(_ message: String) {
        self.init(message: message, line: 1, column: 1)
    }
}
