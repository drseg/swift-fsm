import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SwiftFSMMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EventMacro.self, EventWithValueMacro.self
    ]
}

public struct StaticFuncEventMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext)
    throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticFuncFormatted(functionName: "FSMEvent<String>", argumentLabel: "name")
    }
}

public struct EventMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext)
    throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticLetFormatted(functionName: "event")
    }
}

public struct EventWithValueMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try node.staticLetFormatted(functionName: "eventWithValue")
    }
}

extension ExprSyntax {
    func staticLetFormatted(functionName: String) throws -> DeclSyntax {
        guard
            let segments = self.as(StringLiteralExprSyntax.self)?.segments,
            case .stringSegment(let literalSegment)? = segments.first else {
            throw "Event names must be String literals"
        }

        let text = literalSegment.content.text
        return "static let \(raw: text) = \(raw: functionName)(\"\(raw: text)\")"
    }

    func staticFuncFormatted(functionName: String, argumentLabel: String) throws -> DeclSyntax {
        guard
            let segments = self.as(StringLiteralExprSyntax.self)?.segments,
            case .stringSegment(let literalSegment)? = segments.first else {
            throw "Event names must be String literals"
        }

        let text = literalSegment.content.text
        return """
        static func \(raw: text)() -> \(raw: functionName) {
            \(raw: functionName)(\(raw: argumentLabel): \"\(raw: text)\")
        }
        """
    }
}

extension FreestandingMacroExpansionSyntax {
    func staticLetFormatted(functionName: String) throws -> [DeclSyntax] {
        guard argumentList.count > 0 else {
            throw "Must include at least one String literal argument"
        }

        return try argumentList.map(\.expression).reduce(into: [DeclSyntax]()) {
            $0.append(try $1.staticLetFormatted(functionName: functionName))
        }
    }

    func staticFuncFormatted(functionName: String, argumentLabel: String) throws -> [DeclSyntax] {
        guard argumentList.count > 0 else {
            throw "Must include at least one String literal argument"
        }

        return try argumentList.map(\.expression).reduce(into: [DeclSyntax]()) {
            $0.append(try $1.staticFuncFormatted(functionName: functionName, argumentLabel: argumentLabel))
        }
    }
}

extension String: Error { }
