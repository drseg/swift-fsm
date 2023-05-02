import Foundation

protocol MRNProtocol: Node {
    func finalised() -> (output: [Transition], errors: [Error])
}

class MRNBase {
    var rest: [any Node<IntermediateIO>]
    var errors: [Error] = []
    
    required init(rest: [any Node<IntermediateIO>] = []) {
        self.rest = rest
    }
    
    func validate() -> [Error] {
        errors
    }
}
