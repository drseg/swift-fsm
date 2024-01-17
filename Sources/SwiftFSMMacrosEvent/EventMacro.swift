import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SwiftFSMMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StaticLetEventMacro.self, 
        StaticLetEventWithValueMacro.self,
        StaticFuncEventMacro.self,
        StaticFuncEventWithValueMacro.self
    ]
}

public struct StaticFuncEventMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext)
    throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticFuncFormatted()
    }
}

public struct StaticFuncEventWithValueMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext)
    throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticFuncWithValueFormatted()
    }
}

public struct StaticLetEventMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext)
    throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticLetFormatted(functionName: "event")
    }
}

public struct StaticLetEventWithValueMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticLetFormatted(functionName: "eventWithValue")
    }
}

extension FreestandingMacroExpansionSyntax {
    var argumentError: String { "Must include at least one String literal argument" }

    func validate() throws {
        guard argumentList.count > 0 else { throw argumentError }
    }

    func staticLetFormatted(functionName: String) throws -> [DeclSyntax] {
        try validate()

        return try argumentList.map(\.expression).reduce(into: [DeclSyntax]()) {
            $0.append(try $1.staticLetFormatted(functionName: functionName))
        }
    }

    func staticFuncFormatted() throws -> [DeclSyntax] {
        try validate()

        return try argumentList.map(\.expression).reduce(into: [DeclSyntax]()) {
            $0.append(try $1.staticFuncFormatted())
        }
    }

    func staticFuncWithValueFormatted() throws -> [DeclSyntax] {
        try validate()

        return try argumentList.map(\.expression).reduce(into: [DeclSyntax]()) {
            $0.append(try $1.staticFuncWithFSMValueFormatted())
            $0.append(try $1.staticFuncWithValueFormatted())
        }
    }
}

extension ExprSyntax {
    var argumentError: String {
        "Event names must be String literals"
    }

    var literalText: String? {
        guard
            let segments = self.as(StringLiteralExprSyntax.self)?.segments,
            case .stringSegment(let literalSegment)? = segments.first else {
            return nil
        }

        return literalSegment.content.text
    }

    func staticLetFormatted(functionName: String) throws -> DeclSyntax {
        guard let literalText else {
            throw argumentError
        }

        return "static let \(raw: literalText) = \(raw: functionName)(\"\(raw: literalText)\")"
    }

    func staticFuncFormatted() throws -> DeclSyntax {
        guard let literalText else {
            throw argumentError
        }

        return """
        static func \(raw: literalText)() -> FSMEvent<String> {
            FSMEvent<String>(name: \"\(raw: literalText)\")
        }
        """
    }

    func staticFuncWithValueFormatted() throws -> DeclSyntax {
        guard let literalText else {
            throw argumentError
        }

        return """
        static func \(raw: literalText)<T: Hashable>(_ value: T) -> FSMEvent<T> {
            FSMEvent<T>(FSMValue<T>.some(value), name: \"\(raw: literalText)\")
        }
        """
    }

    func staticFuncWithFSMValueFormatted() throws -> DeclSyntax {
        guard let literalText else {
            throw argumentError
        }

        return """
        static func \(raw: literalText)<T: Hashable>(_ value: FSMValue<T> = .any) -> FSMEvent<T> {
            FSMEvent<T>(value, name: \"\(raw: literalText)\")
        }
        """
    }
}

extension String: Error { }
