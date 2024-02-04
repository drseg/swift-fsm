import Foundation

public protocol SyntaxBuilder {
    associatedtype State: Hashable
    associatedtype Event: Hashable
}
