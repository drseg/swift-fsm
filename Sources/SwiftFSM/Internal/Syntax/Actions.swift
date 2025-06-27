import Foundation

public extension Syntax {
    struct Actions<Event: FSMHashable> {
        let actions: [AnyAction]
        let file: String
        let line: Int

        init(
            _ actions: [AnyAction],
            file: String = #file,
            line: Int = #line
        ) {
            self.actions = actions
            self.file = file
            self.line = line
        }

        public func callAsFunction(
            @MWTABuilder _ group: () -> [MatchingWhenThenActions]
        ) -> MWTA_Group {
            .init(actions, file: file, line: line, group)
        }

        public func callAsFunction(
            @MWABuilder _ group: () -> [MatchingWhenActions]
        ) -> MWA_Group {
            .init(actions, file: file, line: line, group)
        }

        public func callAsFunction(
            @MTABuilder _ group: () -> [MatchingThenActions]
        ) -> MTA_Group {
            .init(actions, file: file, line: line, group)
        }
    }
}
