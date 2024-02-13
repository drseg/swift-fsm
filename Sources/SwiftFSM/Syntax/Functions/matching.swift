import Foundation

public extension ExpandedSyntaxBuilder {
    typealias Matching = Syntax.Expanded.Matching

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
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching<State, Event>(predicate, or: [], and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching<State, Event>(predicate, or: or, and: [], file: file, line: line)
            .callAsFunction(block)
    }

    func matching<P: Predicate>(
        _ predicate: P,
        or: P...,
        and: any Predicate...,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Matching<State, Event>(predicate, or: or, and: and, file: file, line: line)
            .callAsFunction(block)
    }
}
