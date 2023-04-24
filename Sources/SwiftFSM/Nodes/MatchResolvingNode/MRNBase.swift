import Foundation

class MRNBase {
    var rest: [any Node<IntermediateIO>]
    var errors: [Error] = []
    
    init(rest: [any Node<IntermediateIO>] = []) {
        self.rest = rest
    }
    
    func validate() -> [Error] {
        errors
    }
}
