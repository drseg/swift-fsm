import Foundation

final class EagerMatchResolvingNode: MatchResolvingNode {
    struct ErrorOutput {
        let state: AnyTraceable,
            descriptor: MatchDescriptorChain,
            event: AnyTraceable,
            nextState: AnyTraceable

        init(
            _ state: AnyTraceable,
            _ match: MatchDescriptorChain,
            _ event: AnyTraceable,
            _ nextState: AnyTraceable
        ) {
            self.state = state
            self.descriptor = match
            self.event = event
            self.nextState = nextState
        }
    }

    struct RankedOutput {
        let state: AnyTraceable,
            descriptor: MatchDescriptorChain,
            predicateResult: RankedPredicates,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [AnyAction]

        var toTransition: Transition {
            Transition(descriptor.condition,
                       state.base,
                       predicateResult.predicates,
                       event.base,
                       nextState.base,
                       actions)
        }

        var toErrorOutput: ErrorOutput {
            ErrorOutput(state, descriptor, event, nextState)
        }
    }

    struct ImplicitClashesError: Error {
        let clashes: ImplicitClashesDictionary
    }

    struct ImplicitClashesKey: FSMHashable {
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
    
    var rest: [any SyntaxNode<OverrideSyntaxDTO>]
    var errors: [Error] = []

    required init(rest: [any SyntaxNode<OverrideSyntaxDTO>] = []) {
        self.rest = rest
    }

    func combinedWith(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        var clashes = ImplicitClashesDictionary()
        let allCases = rest.allCases()

        let result = rest.reduce(into: [RankedOutput]()) { result, input in
            func appendInput(_ predicateResult: RankedPredicates = RankedPredicates.empty) {
                let ro = RankedOutput(state: input.state,
                                      descriptor: input.descriptor,
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

            let allPredicateCombinations = input.descriptor.allPredicateCombinations(allCases)
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
    static var empty: Self {
        Self([], priority: 0)
    }
}

extension [SemanticValidationNode.Output] {
    func allCases() -> PredicateSets {
        let descriptors = map(\.descriptor)
        let anys = descriptors.map(\.matchingAny)
        let alls = descriptors.map(\.matchingAll)
        return (alls + anys.flattened).flattened.combinationsOfAllCases
    }
}
