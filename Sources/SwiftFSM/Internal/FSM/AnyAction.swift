import Foundation

public typealias FSMAction = @isolated(any) () async -> Void
public typealias FSMActionWithEvent<Event: FSMHashable> = @isolated(any) (Event) async -> Void

public struct AnyAction: @unchecked Sendable {
    public enum NullEvent: FSMHashable { case null }

    private let base: Any

    init(_ action: @escaping FSMAction) {
        base = action
    }

    init<Event: FSMHashable>(_ action: @escaping FSMActionWithEvent<Event>) {
        base = action
    }

    func callAsFunction<Event: FSMHashable>(_ event: Event = NullEvent.null) async {
        if let base = self.base as? FSMAction {
            await base()
        } else if let base = self.base as? FSMActionWithEvent<Event> {
            await base(event)
        }
    }
}
