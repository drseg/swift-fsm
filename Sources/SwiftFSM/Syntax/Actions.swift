import Foundation

public extension Syntax {
    struct Actions {
        let actions: [Action]
        let file: String
        let line: Int
        
        public init(_ actions: @escaping Action, file: String = #file, line: Int = #line) {
            self.init([actions], file: file, line: line)
        }
        
        public init(_ actions: [Action], file: String = #file, line: Int = #line) {
            self.actions = actions
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
