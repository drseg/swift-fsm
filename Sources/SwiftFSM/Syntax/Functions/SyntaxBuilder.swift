import Foundation

public typealias FSMType = Hashable & Sendable

public protocol SyntaxBuilder {
    associatedtype State: FSMType
    associatedtype Event: FSMType
}
