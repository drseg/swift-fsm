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

public struct StaticFuncEventWithValueMacro: DeclarationMacro {
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
            throw "Event names must be String literals"
        }

        return "static let \(raw: literalText) = \(raw: functionName)(\"\(raw: literalText)\")"
    }

    func staticFuncFormatted(functionName: String, argumentLabel: String) throws -> DeclSyntax {
        guard let literalText else {
            throw "Event names must be String literals"
        }

        return """
        static func \(raw: literalText)() -> () -> \(raw: functionName) {
            {
                \(raw: functionName)(\(raw: argumentLabel): \"\(raw: literalText)\")
            }
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
