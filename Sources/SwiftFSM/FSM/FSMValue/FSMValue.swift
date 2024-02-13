import Foundation

protocol FSMValueErrorHandler {
    func throwError(
        typeName: String,
        instanceName: String,
        function: String
    ) throws -> Never
}

private struct ErrorHandler: FSMValueErrorHandler {
    func throwError(
        typeName: String,
        instanceName: String,
        function: String
    ) throws -> Never {
        throw "\(typeName).\(instanceName) has no value - the operation \(function) is invalid."
    }
}

#warning("uncomment below in Xcode 15.3/Swift 5.10 to fix the other warnings")
/*nonisolated(unsafe)*/ private var errorHandler: any FSMValueErrorHandler = ErrorHandler()

public enum FSMValue<T: FSMHashable>: FSMHashable {
    case some(T), any

    static func setErrorHandler(_ h: some FSMValueErrorHandler) {
        errorHandler = h
    }

    static func resetErrorHandler() {
        errorHandler = ErrorHandler()
    }

    public var wrappedValue: T? {
        try? throwingWrappedValue("")
    }

    func unsafeWrappedValue(_ f: String = #function) -> T {
        try! throwingWrappedValue(f)
    }

    func throwingWrappedValue(_ f: String) throws -> T {
        return switch self {
        case let .some(value):
            value
        default:
            try errorHandler.throwError(
                typeName: String(describing: Self.self),
                instanceName: String(describing: self),
                function: f
            )
        }
    }

    var isSome: Bool {
        return if case .some = self {
            true
        } else {
            false
        }
    }
}

public protocol EventWithValues: FSMHashable { }
extension EventWithValues {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(caseName)
    }

    var caseName: some StringProtocol {
        String(describing: self).lazy.split(separator: "(").first!
    }
}
