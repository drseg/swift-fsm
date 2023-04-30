import Foundation

class MRNBase: UnsafeNode {
    var rest: [any UnsafeNode]
    var errors: [Error] = []
    
    required init(rest: [any UnsafeNode] = []) {
        self.rest = rest
    }
    
    func validate() -> [Error] {
        errors
    }
    
    func combinedWithRest(_ rest: [IntermediateIO]) -> [Transition] {
        fatalError("subclasses must implement")
    }
}
