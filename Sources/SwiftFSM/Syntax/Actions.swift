import Foundation

public extension Syntax {
    struct Actions<Event: Hashable> {
        let actions: [AnyAction]
        let file: String
        let line: Int

        public init(
            _ actions: @escaping FSMSyncAction,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([actions], file: file, line: line)
        }

        public init(
            _ actions: @escaping FSMAsyncAction,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([actions], file: file, line: line)
        }

        public init(
            _ actions: @escaping FSMSyncActionWithEvent<Event>,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([actions], file: file, line: line)
        }

        public init(
            _ actions: @escaping FSMAsyncActionWithEvent<Event>,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([actions], file: file, line: line)
        }

        init(
            _ actions: [FSMSyncAction],
            file: String = #file,
            line: Int = #line
        ) {
            self.actions = actions.map(AnyAction.init)
            self.file = file
            self.line = line
        }

        init(
            _ actions: [FSMAsyncAction],
            file: String = #file,
            line: Int = #line
        ) {
            self.actions = actions.map(AnyAction.init)
            self.file = file
            self.line = line
        }

        init(
            _ actions: [FSMSyncActionWithEvent<Event>],
            file: String = #file,
            line: Int = #line
        ) {
            self.actions = actions.map(AnyAction.init)
            self.file = file
            self.line = line
        }

        init(
            _ actions: [FSMAsyncActionWithEvent<Event>],
            file: String = #file,
            line: Int = #line
        ) {
            self.actions = actions.map(AnyAction.init)
            self.file = file
            self.line = line
        }

        public func callAsFunction(
            @Internal.MWTABuilder _ block: () -> [MWTA]
        ) -> Internal.MWTASentence {
            .init(actions, file: file, line: line, block)
        }

        public func callAsFunction(
            @Internal.MWABuilder _ block: () -> [MWA]
        ) -> Internal.MWASentence {
            .init(actions, file: file, line: line, block)
        }

        public func callAsFunction(
            @Internal.MTABuilder _ block: () -> [MTA]
        ) -> Internal.MTASentence {
            .init(actions, file: file, line: line, block)
        }
    }
}
