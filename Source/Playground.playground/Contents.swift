protocol GenericProtocol<GP> {
    associatedtype GP: Hashable
}

class GPImpl: GenericProtocol, Hashable {
    static func == (lhs: GPImpl, rhs: GPImpl) -> Bool {
        true
    }
    
    func hash(into hasher: inout Hasher) {
        
    }
    
    typealias GP = GPImpl
}

struct Generic1<A: Hashable> {
    let c: any GenericProtocol<A>
}

let g = Generic1(c: GPImpl())
