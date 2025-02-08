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
            @MWTABuilder _ block: @isolated(any) () -> [MWTA]
        ) -> MWTABlock {
            .init(actions, file: file, line: line, block)
        }

        public func callAsFunction(
            @MWABuilder _ block: @isolated(any) () -> [MWA]
        ) -> MWABlock {
            .init(actions, file: file, line: line, block)
        }

        public func callAsFunction(
            @MTABuilder _ block: @isolated(any) () -> [MTA]
        ) -> MTABlock {
            .init(actions, file: file, line: line, block)
        }
    }
}
