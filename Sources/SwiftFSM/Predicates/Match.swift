import Foundation

final class Match: Sendable {
    typealias Result = Swift.Result<Match, MatchError>
    typealias AnyPP = any Predicate

    let matchAny: [[AnyPredicate]]
    let matchAll: [AnyPredicate]

    let condition: ConditionAction?
    let next: Match?
    let originalSelf: Match?

    let file: String
    let line: Int

    convenience init(condition: @escaping ConditionAction, file: String = #file, line: Int = #line) {
        self.init(any: [], all: [], condition: condition, file: file, line: line)
    }

    convenience init(any: AnyPP..., all: AnyPP..., file: String = #file, line: Int = #line) {
        self.init(any: any.erased(), all: all.erased(), file: file, line: line)
    }

    convenience init(any: [[AnyPP]], all: AnyPP..., file: String = #file, line: Int = #line) {
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
        condition: ConditionAction? = nil,
        next: Match? = nil,
        originalSelf: Match? = nil,
        file: String = #file,
        line: Int = #line
    ) {
        self.matchAny = any
        self.matchAll = all
        self.condition = condition
        self.next = next
        self.originalSelf = originalSelf
        self.file = file
        self.line = line
    }

    func prepend(_ m: Match) -> Match {
        .init(any: m.matchAny,
              all: m.matchAll,
              condition: m.condition,
              next: self,
              originalSelf: m.originalSelf,
              file: m.file,
              line: m.line)
    }

    func finalised() -> Result {
        guard let next else { return self.validate() }

        let firstResult = self.validate()
        let restResult = next.finalised()

        return switch (firstResult, restResult) {
        case (.success, .success(let rest)):
            adding(rest).validate().appending(file: rest.file, line: rest.line)

        case (.failure, .failure(let e)):
            firstResult.appending(files: e.files, lines: e.lines)

        case (.success, .failure):
            restResult

        case (.failure, .success):
            firstResult
        }
    }

    func validate() -> Result {
        func failure<C: Collection>(predicates: C, type: MatchError.Type) -> Result
        where C.Element == AnyPredicate {
            .failure(
                type.init(
                    predicates: predicates,
                    files: [file],
                    lines: [line]
                )
            )
        }

        guard matchAll.areUniquelyTyped else {
            return failure(predicates: matchAll, type: DuplicateMatchTypes.self)
        }

        guard matchAny.flattened.elementsAreUnique else {
            return failure(predicates: matchAny.flattened, type: DuplicateAnyValues.self)
        }

        guard matchAny.hasNoDuplicateTypes else {
            return failure(predicates: matchAny.flattened, type: DuplicateMatchTypes.self)
        }

        guard matchAny.hasNoConflictingTypes else {
            return failure(predicates: matchAny.flattened, type: ConflictingAnyTypes.self)
        }

        let duplicates = matchAll.filter { matchAny.flattened.contains($0) }
        guard duplicates.isEmpty else {
            return failure(predicates: duplicates, type: DuplicateAnyAllValues.self)
        }

        return .success(self)
    }

    func adding(_ other: Match) -> Match {
        var condition: ConditionAction? {
            switch (self.condition == nil, other.condition == nil) {
            case (true, true): nil
            case (true, false): other.condition!
            case (false, true): self.condition!
            case (false, false): { self.condition!() && other.condition!() }
            }
        }

        return Match(any: matchAny + other.matchAny,
                     all: matchAll + other.matchAll,
                     condition: condition,
                     next: next,
                     originalSelf: self,
                     file: file,
                     line: line)
    }

    func allPredicateCombinations(_ predicatePool: PredicateSets) -> Set<RankedPredicates> {
        let anyAndAll = combineAnyAndAll().removingEmpties

        return predicatePool.reduce(into: []) { result, poolElement in
            func insertPoolElement(rank: Int) {
                result.insert(.init(poolElement, rank: rank))
            }

            guard !anyAndAll.isEmpty else { insertPoolElement(rank: 0); return }

            anyAndAll.forEach {
                if $0.allSatisfy(poolElement.contains) {
                    insertPoolElement(rank: $0.count)
                }
            }
        }
    }

    func combineAnyAndAll() -> PredicateSets {
        matchAny.combinations().reduce(into: PredicateSets()) {
            $0.insert(Set(matchAll + $1))
        } ??? [matchAll].asSets
    }
}

extension Match: Hashable {
    public static func == (lhs: Match, rhs: Match) -> Bool {
        func sort(_ any: [[AnyPredicate]]) -> [[AnyPredicate]] {
            any.map { $0.sorted(by: sort) }
        }

        func sort(_ p1: AnyPredicate, _ p2: AnyPredicate) -> Bool {
            String(describing: p1) > String(describing: p2)
        }

        let lhsAny = sort(lhs.matchAny)
        let rhsAny = sort(rhs.matchAny)

        return lhs.matchAny.count == rhs.matchAny.count &&
        lhs.matchAll.count == rhs.matchAll.count &&
        lhsAny.allSatisfy({ rhsAny.contains($0) }) &&
        lhs.matchAll.allSatisfy({ rhs.matchAll.contains($0) })
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(matchAny)
        hasher.combine(matchAll)
    }
}

struct RankedPredicates: FSMHashable {
    let predicates: PredicateSet
    let rank: Int

    init(_ predicates: PredicateSet, rank: Int) {
        self.predicates = predicates
        self.rank = rank
    }
}

extension Match.Result {
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
