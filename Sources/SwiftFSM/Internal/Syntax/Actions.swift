import Foundation

public extension Internal {
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
            @Internal.MWTABuilder _ block: @isolated(any) () -> [MWTA]
        ) -> Internal.MWTABlock {
            .init(actions, file: file, line: line, block)
        }

        public func callAsFunction(
            @Internal.MWABuilder _ block: @isolated(any) () -> [MWA]
        ) -> Internal.MWABlock {
            .init(actions, file: file, line: line, block)
        }

        public func callAsFunction(
            @Internal.MTABuilder _ block: @isolated(any) () -> [MTA]
        ) -> Internal.MTABlock {
            .init(actions, file: file, line: line, block)
        }
    }
}
