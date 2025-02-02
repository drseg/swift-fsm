import Foundation

typealias PredicateSets = Set<PredicateSet>
typealias PredicateSet = Set<AnyPredicate>

public protocol Predicate: CaseIterable, FSMHashable { }

extension Predicate {
    func erased() -> AnyPredicate {
        AnyPredicate(base: self)
    }

    var allCases: [any Predicate] {
        Self.allCases as! [any Predicate]
    }
}

struct AnyPredicate: @unchecked Sendable, Hashable, CustomStringConvertible {
    let base: AnyHashable

    init<P: Predicate>(base: P) {
        self.base = AnyHashable(base)
    }

    func unwrap<P: Predicate>(to: P.Type) -> P {
        base as! P
    }

    var allCases: [Self] {
        (base as! any Predicate).allCases.erased()
    }

    var description: String {
        type + "." + String(describing: base)
    }

    var type: String {
        String(describing: Swift.type(of: base.base))
    }
}

extension Array {
    func erased() -> [AnyPredicate] where Element: Predicate { _erased() }
    func erased() -> [AnyPredicate] where Element == any Predicate { _erased() }

    private func _erased() -> [AnyPredicate] {
        map { ($0 as! any Predicate).erased() }
    }
}

extension Collection where Element == AnyPredicate {
    var combinationsOfAllCases: PredicateSets {
        Set(uniqueTypes()
            .map(\.allCases)
            .combinations()
            .map(Set.init)
        )
    }

    func uniqueTypes() -> [AnyPredicate] {
        uniqueElementTypes.reduce(into: []) { predicates, type in
            predicates.append(first { $0.type == type }!)
        }
    }

    var elementsAreUnique: Bool {
        Set(self).count == count
    }

    var areUniquelyTyped: Bool {
        uniqueElementTypes.count == count
    }

    var uniqueElementTypes: Set<String> {
        Set(map(\.type))
    }
}
