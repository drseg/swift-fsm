import Foundation

public protocol ExpandedSyntaxBuilder: SyntaxBuilder { }

// MARK: - Matching
public extension ExpandedSyntaxBuilder {
    typealias Matching = Syntax.Matching

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line
    ) -> Matching<State, Event> {
        .init(predicate, or: [], and: [], file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line
    ) -> Matching<State, Event> {
        .init(predicate, or: or, and: [], file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        and: P...,
        file: String = #file,
        line: Int = #line
    ) -> Matching<State, Event> {
        .init(predicate, or: [], and: and, file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Matching<State, Event> {
        .init(predicate, or: or, and: and, file: file, line: line)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }
}

// MARK: - Condition
public extension ExpandedSyntaxBuilder {
    typealias Condition = Syntax.Condition

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ block: () -> [Syntax.MWTA]
    ) -> Syntax.MWTABlock {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line
    ) -> Condition<State, Event> {
        .init(condition, file: file, line: line)
    }

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ block: () -> [Syntax.MWA]
    ) -> Syntax.MWABlock {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ block: () -> [Syntax.MTA]
    ) -> Syntax.MTABlock {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }
}

