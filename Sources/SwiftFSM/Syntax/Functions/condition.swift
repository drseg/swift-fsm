import Foundation

public extension ExpandedSyntaxBuilder {
    typealias Condition = Syntax.Expanded.Condition

    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }

    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line
    ) -> Condition<State, Event> {
        .init(condition, file: file, line: line)
    }

    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }

    func condition(
        _ condition: @escaping () -> Bool,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }
}
