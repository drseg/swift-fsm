import Foundation

public extension SyntaxBuilder {
    func overrides(
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> [MWTA] {
        Syntax.Override().callAsFunction(block)
    }
}
