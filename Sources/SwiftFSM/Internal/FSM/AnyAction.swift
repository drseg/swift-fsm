import Foundation

public typealias Action = @isolated(any) () async -> Void
public typealias ActionWithEvent<Event: FSMHashable> = @isolated(any) (Event) async -> Void

public struct AnyAction: @unchecked Sendable {
    internal struct NullEvent: FSMHashable { }

    private let base: Any

    init(_ action: @escaping Action) {
        base = action
    }

    init<Event: FSMHashable>(_ action: @escaping ActionWithEvent<Event>) {
        base = action
    }

    internal func callAsFunction<Event: FSMHashable>(_ event: Event = NullEvent()) async {
        if let base = self.base as? Action {
            await base()
        } else if let base = self.base as? ActionWithEvent<Event> {
            await base(event)
        }
    }
}
