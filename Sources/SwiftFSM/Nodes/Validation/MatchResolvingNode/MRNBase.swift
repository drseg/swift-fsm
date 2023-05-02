import Foundation

protocol MRNProtocol: UnsafeNode {
    func finalised() -> (output: [Transition], errors: [Error])
}

class MRNBase {
    var rest: [any UnsafeNode]
    var errors: [Error] = []
    
    required init(rest: [any UnsafeNode] = []) {
        self.rest = rest
    }
    
    func validate() -> [Error] {
        errors
    }
}
