import Foundation

struct Transition {
    let condition: (() -> Bool)?,
        state: AnyHashable,
        predicates: PredicateSet,
        event: AnyHashable,
        nextState: AnyHashable,
        actions: [AnyAction]

    init(
        _ condition: (() -> Bool)?,
        _ state: AnyHashable,
        _ predicates: PredicateSet,
        _ event: AnyHashable,
        _ nextState: AnyHashable,
        _ actions: [AnyAction]
    ) {
        self.condition = condition
        self.state = state
        self.predicates = predicates
        self.event = event
        self.nextState = nextState
        self.actions = actions
    }
}

final class EagerMatchResolvingNode: MRNBase, MRNProtocol {
    struct ErrorOutput {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable

        init(
            _ state: AnyTraceable,
            _ match: Match,
            _ event: AnyTraceable,
            _ nextState: AnyTraceable
        ) {
            self.state = state
            self.match = match
            self.event = event
            self.nextState = nextState
        }
    }

    struct RankedOutput {
        let state: AnyTraceable,
            match: Match,
            predicateResult: RankedPredicates,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [AnyAction]

        var toTransition: Transition {
            Transition(match.condition,
                       state.base,
                       predicateResult.predicates,
                       event.base,
                       nextState.base,
                       actions)
        }

        var toErrorOutput: ErrorOutput {
            ErrorOutput(state, match, event, nextState)
        }
    }

    struct ImplicitClashesError: Error {
        let clashes: ImplicitClashesDictionary
    }

    struct ImplicitClashesKey: Hashable {
        let state: AnyTraceable,
            predicates: PredicateSet,
            event: AnyTraceable

        init(_ state: AnyTraceable, _ predicates: PredicateSet, _ event: AnyTraceable) {
            self.state = state
            self.predicates = predicates
            self.event = event
        }

        init(_ output: RankedOutput) {
            self.state = output.state
            self.predicates = output.predicateResult.predicates
            self.event = output.event
        }
    }

    typealias ImplicitClashesDictionary = [ImplicitClashesKey: [ErrorOutput]]

    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        var clashes = ImplicitClashesDictionary()
        let allCases = rest.allCases()

        let result = rest.reduce(into: [RankedOutput]()) { result, input in
            func appendInput(_ predicateResult: RankedPredicates = RankedPredicates()) {
                let ro = RankedOutput(state: input.state,
                                      match: input.match,
                                      predicateResult: predicateResult,
                                      event: input.event,
                                      nextState: input.nextState,
                                      actions: input.actions)

                func isRankedClash(_ lhs: RankedOutput) -> Bool {
                    isClash(lhs) && lhs.predicateResult.rank != ro.predicateResult.rank
                }

                func isClash(_ lhs: RankedOutput) -> Bool {
                    ImplicitClashesKey(lhs) == ImplicitClashesKey(ro)
                }

                func highestRank(_ lhs: RankedOutput, _ rhs: RankedOutput) -> RankedOutput {
                    lhs.predicateResult.rank > rhs.predicateResult.rank ? lhs : rhs
                }

                if let i = result.firstIndex(where: isRankedClash) {
                    result[i] = highestRank(result[i], ro)
                } else {
                    if let clash = result.first(where: isClash) {
                        let key = ImplicitClashesKey(ro)
                        clashes[key] = (clashes[key] ?? [clash.toErrorOutput]) + [ro.toErrorOutput]
                    }
                    result.append(ro)
                }
            }

            let allPredicateCombinations = input.match.allPredicateCombinations(allCases)
            guard !allPredicateCombinations.isEmpty else {
                appendInput(); return
            }

            allPredicateCombinations.forEach(appendInput)
        }

        if !clashes.isEmpty {
            errors.append(ImplicitClashesError(clashes: clashes))
        }

        return result.map(\.toTransition)
    }
}

extension RankedPredicates {
    init() {
        predicates = []
        rank = 0
    }
}

extension [SemanticValidationNode.Output] {
    func allCases() -> PredicateSets {
        let matches = map(\.match)
        let anys = matches.map(\.matchAny)
        let alls = matches.map(\.matchAll)
        return (alls + anys.flattened).flattened.combinationsOfAllCases
    }
}
