import Foundation

final class MatchDescriptorChain: Sendable {
    typealias ResolvedMatchDescriptor = Swift.Result<MatchDescriptorChain, MatchError>
    typealias AnyPP = any Predicate
    
    let matchingAny: [[AnyPredicate]]
    let matchingAll: [AnyPredicate]
    let condition: ConditionProvider?
    
    let childDescriptor: MatchDescriptorChain?
    let originalSelf: MatchDescriptorChain?
    
    let file: String
    let line: Int
    
    convenience init(
        condition: @escaping ConditionProvider,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [], all: [], condition: condition, file: file, line: line)
    }
    
    convenience init(
        any: AnyPP...,
        all: AnyPP...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: any.erased(), all: all.erased(), file: file, line: line)
    }
    
    convenience init(
        any: [[AnyPP]],
        all: AnyPP...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: any.map { $0.erased() }, all: all.erased(), file: file, line: line)
    }
    
    convenience init(
        any: [AnyPredicate],
        all: [AnyPredicate],
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any].filter { !$0.isEmpty }, all: all, file: file, line: line)
    }
    
    init(
        any: [[AnyPredicate]],
        all: [AnyPredicate],
        condition: ConditionProvider? = nil,
        childDescriptor: MatchDescriptorChain? = nil,
        originalSelf: MatchDescriptorChain? = nil,
        file: String = #file,
        line: Int = #line
    ) {
        self.matchingAny = any
        self.matchingAll = all
        self.condition = condition
        self.childDescriptor = childDescriptor
        self.originalSelf = originalSelf
        self.file = file
        self.line = line
    }
}

extension MatchDescriptorChain {
    func prepend(_ m: MatchDescriptorChain) -> MatchDescriptorChain {
        .init(any: m.matchingAny,
              all: m.matchingAll,
              condition: m.condition,
              childDescriptor: self,
              originalSelf: m.originalSelf,
              file: m.file,
              line: m.line)
    }

    func resolve() -> ResolvedMatchDescriptor {
        guard let childDescriptor else { return self.validate() }

        let firstResult = self.validate()
        let restResult = childDescriptor.resolve()

        return switch (firstResult, restResult) {
        case (.success, .success(let rest)):
            combineWith(rest)
                .validate()
                .appending(file: rest.file, line: rest.line)

        case (.failure, .failure(let e)):
            firstResult
                .appending(files: e.files, lines: e.lines)

        case (.success, .failure):
            restResult

        case (.failure, .success):
            firstResult
        }
    }

    func validate() -> ResolvedMatchDescriptor {
        func failure<C: Collection<AnyPredicate>>(
            predicates: C,
            type: MatchError.Type
        ) -> ResolvedMatchDescriptor {
            .failure(
                type.init(
                    predicates: predicates,
                    files: [file],
                    lines: [line]
                )
            )
        }

        guard matchingAll.areUniquelyTyped else {
            return failure(predicates: matchingAll, type: DuplicateMatchTypes.self)
        }

        guard matchingAny.flattened.elementsAreUnique else {
            return failure(predicates: matchingAny.flattened, type: DuplicateAnyValues.self)
        }

        guard matchingAny.hasNoDuplicateTypes else {
            return failure(predicates: matchingAny.flattened, type: DuplicateMatchTypes.self)
        }

        guard matchingAny.hasNoConflictingTypes else {
            return failure(predicates: matchingAny.flattened, type: ConflictingAnyTypes.self)
        }

        let duplicates = matchingAll.filter { matchingAny.flattened.contains($0) }
        guard duplicates.isEmpty else {
            return failure(predicates: duplicates, type: DuplicateAnyAllValues.self)
        }

        return .success(self)
    }

    func combineWith(_ other: MatchDescriptorChain) -> MatchDescriptorChain {
        var condition: ConditionProvider? {
            return switch (self.condition == nil, other.condition == nil) {
            case (true, true): nil
            case (true, false): other.condition!
            case (false, true): self.condition!
            case (false, false): { self.condition!() && other.condition!() }
            }
        }
        
        return MatchDescriptorChain(
            any: matchingAny + other.matchingAny,
            all: matchingAll + other.matchingAll,
            condition: condition,
            childDescriptor: childDescriptor,
            originalSelf: self,
            file: file,
            line: line
        )
    }

    func allPredicateCombinations(_ predicatePool: PredicateSets) -> Set<RankedPredicates> {
        let anyAndAll = combineAnyAndAll().removingEmpties

        return predicatePool.reduce(into: []) { result, poolElement in
            func insertPoolElement(priority: Int) {
                result.insert(.init(poolElement, priority: priority))
            }

            guard !anyAndAll.isEmpty else { insertPoolElement(priority: 0); return }

            anyAndAll.forEach {
                if $0.allSatisfy(poolElement.contains) {
                    insertPoolElement(priority: $0.count)
                }
            }
        }
    }

    func combineAnyAndAll() -> PredicateSets {
        matchingAny.combinations().reduce(into: PredicateSets()) {
            $0.insert(Set(matchingAll + $1))
        } ??? [matchingAll].asSets
    }
}

extension MatchDescriptorChain: Hashable {
    public static func == (lhs: MatchDescriptorChain, rhs: MatchDescriptorChain) -> Bool {
        func sort(_ any: [[AnyPredicate]]) -> [[AnyPredicate]] {
            any.map { $0.sorted(by: sort) }
        }

        func sort(_ p1: AnyPredicate, _ p2: AnyPredicate) -> Bool {
            String(describing: p1) > String(describing: p2)
        }

        let lhsAny = sort(lhs.matchingAny)
        let rhsAny = sort(rhs.matchingAny)

        return lhs.matchingAny.count == rhs.matchingAny.count &&
        lhs.matchingAll.count == rhs.matchingAll.count &&
        lhsAny.allSatisfy({ rhsAny.contains($0) }) &&
        lhs.matchingAll.allSatisfy({ rhs.matchingAll.contains($0) })
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(matchingAny)
        hasher.combine(matchingAll)
    }
}

struct RankedPredicates: FSMHashable {
    let predicates: PredicateSet
    let rank: Int

    init(_ predicates: PredicateSet, priority: Int) {
        self.predicates = predicates
        self.rank = priority
    }
}

extension MatchDescriptorChain.ResolvedMatchDescriptor {
    func appending(file: String, line: Int) -> Self {
        appending(files: [file], lines: [line])
    }

    func appending(files: [String], lines: [Int]) -> Self {
        mapError { $0.append(files: files, lines: lines) }
    }
}

extension Collection where Element: Collection & FSMHashable, Element.Element: FSMHashable {
    var asSets: Set<Set<Element.Element>> {
        Set(map(Set.init)).removingEmpties
    }

    var removingEmpties: Set<Element> {
        Set(filter { !$0.isEmpty })
    }
}

extension [[AnyPredicate]] {
    var hasNoConflictingTypes: Bool {
        allSatisfy { eachAny in
            eachAny.allSatisfy {
                $0.type == eachAny.first!.type
            }
        }
    }

    var hasNoDuplicateTypes: Bool {
        var anyOf = map { $0.map(\.type) }

        while anyOf.count > 1 {
            let first = anyOf.first!
            let rest = anyOf.dropFirst()

            for type in first where rest.flattened.contains(type) {
                return false
            }
            anyOf = rest.map { $0 }
        }

        return true
    }
}
