protocol StateProtocol: Hashable {}
protocol EventProtocol: Hashable {}
protocol PredicateProtocol: CaseIterable, Hashable {}

typealias SP = StateProtocol
typealias EP = EventProtocol
typealias PP = PredicateProtocol

extension PredicateProtocol {
    func isEqual(to rhs: any PredicateProtocol) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return rhs == self
    }
    
    var erased: AnyPredicate {
        AnyPredicate(base: self)
    }
    
    var allCases: [any PredicateProtocol] {
        return type(of: self).allCases as! [any PredicateProtocol]
    }
}

struct AnyPredicate: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.base.isEqual(to: rhs.base)
    }
    
    let base: any PredicateProtocol
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

enum P: PredicateProtocol {
    case a, b, c
}

let pred = P.a
let cases = pred.allCases
let firstCase = cases.first!
let firstCaseErased = firstCase.erased
var setofAllCases = Set(cases.map(\.erased))
setofAllCases.remove(firstCaseErased)
print(setofAllCases.map(\.base))
