import Foundation

public typealias FSMHashable = Hashable & Sendable

public protocol SyntaxBuilder {
    associatedtype State: FSMHashable
    associatedtype Event: FSMHashable
}
