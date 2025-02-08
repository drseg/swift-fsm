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
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MTA_Group {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(group)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MTA_Group {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(group)
    }
}

// MARK: - Condition
public extension ExpandedSyntaxBuilder {
    typealias Condition = Syntax.Condition

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Syntax.MWTABuilder _ group: () -> [Syntax.MatchingWhenThenActions]
    ) -> Syntax.MWTA_Group {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(group)
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
        @Syntax.MWABuilder _ group: () -> [Syntax.MatchingWhenActions]
    ) -> Syntax.MWA_Group {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(group)
    }

    func condition(
        _ condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line,
        @Syntax.MTABuilder _ group: () -> [Syntax.MatchingThenActions]
    ) -> Syntax.MTA_Group {
        Condition<State, Event>(condition, file: file, line: line)
            .callAsFunction(group)
    }
}

