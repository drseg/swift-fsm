import Foundation

final class LazyMatchResolvingNode: Node {
    var rest: [any Node<Input>]
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        []
    }
}
