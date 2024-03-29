import Foundation

public extension SyntaxBuilder {
    func actions(
        _ action: @escaping FSMSyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Internal.MWTABuilder _ block: () -> [MWTA]
    ) -> Internal.MWTASentence {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Internal.MWABuilder _ block: () -> [MWA]
    ) -> Internal.MWASentence {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncAction,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMSyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ action: @escaping FSMAsyncActionWithEvent<Event>,
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(Array(action), file: file, line: line)
            .callAsFunction(block)
    }

    func actions(
        _ actions: [AnyAction],
        file: String = #file,
        line: Int = #line,
        @Internal.MTABuilder _ block: () -> [MTA]
    ) -> Internal.MTASentence {
        Syntax.Actions<Event>(actions, file: file, line: line)
            .callAsFunction(block)
    }
}
