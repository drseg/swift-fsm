import Foundation

public protocol ExpandedSyntaxBuilder: SyntaxBuilder { }

// MARK: - Matching
public extension ExpandedSyntaxBuilder {
    typealias Matching = Internal.Matching

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
        @Internal.MWTABuilder _ block: @Sendable () -> [Internal.MWTA]
    ) -> Internal.MWTABlock {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: @Sendable () -> [Internal.MWTA]
    ) -> Internal.MWTABlock {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: @Sendable () -> [Internal.MWTA]
    ) -> Internal.MWTABlock {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: @Sendable () -> [Internal.MWA]
    ) -> Internal.MWABlock {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: @Sendable () -> [Internal.MWA]
    ) -> Internal.MWABlock {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: @Sendable () -> [Internal.MWA]
    ) -> Internal.MWABlock {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: @Sendable () -> [Internal.MTA]
    ) -> Internal.MTABlock {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: @Sendable () -> [Internal.MTA]
    ) -> Internal.MTABlock {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: @Sendable () -> [Internal.MTA]
    ) -> Internal.MTABlock {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }
}

// MARK: - Condition
public extension ExpandedSyntaxBuilder {
    typealias Condition = Internal.Condition

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: @Sendable () -> [Internal.MWTA]
    ) -> Internal.MWTABlock {
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
        @Internal.MWABuilder _ block: @Sendable () -> [Internal.MWA]
    ) -> Internal.MWABlock {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: @Sendable () -> [Internal.MTA]
    ) -> Internal.MTABlock {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(block)
    }
}

