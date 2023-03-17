//
//  TableNode.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

struct TableNodeErrorKey: Hashable {
    let state: AnyTraceable, pr: PredicateResult, event: AnyTraceable
}

typealias TableNodeOutput = (state: AnyTraceable,
                             pr: PredicateResult,
                             event: AnyTraceable,
                             nextState: AnyTraceable,
                             actions: [Action],
                             entryActions: [Action],
                             exitActions: [Action])

protocol TableNodeProtocol: AnyObject, Node {
    typealias ErrorDictionary = [TableNodeErrorKey: [PossibleError]]
    typealias PossibleError = (state: AnyTraceable,
                               pr: PredicateResult,
                               match: Match,
                               event: AnyTraceable,
                               nextState: AnyTraceable)
    
    var rest: [any Node<DefineNode.Output>] { get }
    var errors: [Error] { get set }
    
    func _combinedWithRest(
        _ rest: [DefineNode.Output],
        duplicates: inout ErrorDictionary,
        clashes: inout ErrorDictionary
    ) -> [TableNodeOutput]
    
    func areDuplicates(_ lhs: PossibleError, _ rhs: PossibleError) -> Bool
}

extension TableNodeProtocol {
    func areClashes(_ lhs: PossibleError, _ rhs: PossibleError) -> Bool {
        (lhs.0, lhs.1, lhs.3) == (rhs.0, rhs.1, rhs.3)
    }
    
    typealias OutputTuple = (output: TableNodeOutput, candidate: PossibleError, key: TableNodeErrorKey)
    
    func outputComponents(
        _ dno: DefineNode.Output,
        pr: PredicateResult
    ) -> OutputTuple {
        let tno = (state: dno.state,
                   pr: pr,
                   event: dno.event,
                   nextState: dno.nextState,
                   actions: dno.actions,
                   entryActions: dno.entryActions,
                   exitActions: dno.exitActions)
        
        let possibleError = (tno.state, tno.pr, dno.match, tno.event, tno.nextState)
        let key = TableNodeErrorKey(state: tno.state, pr: tno.pr, event: tno.event)
        
        return (tno, possibleError, key)
    }
    
    func addErrorCandidate(
        existing: PossibleError,
        current: PossibleError,
        to collection: inout ErrorDictionary
    ) {
        let key = TableNodeErrorKey(state: current.state,
                                    pr: current.pr,
                                    event: current.event)
        collection[key] = (collection[key] ?? [existing]) + [current]
    }
    
    func combinedWithRest(_ rest: [DefineNode.Output]) -> [TableNodeOutput] {
        var duplicates = ErrorDictionary()
        var clashes = ErrorDictionary()
        
        let output = _combinedWithRest(rest, duplicates: &duplicates, clashes: &clashes)
        
        if !duplicates.isEmpty { errors.append(DuplicatesError(duplicates)) }
        if !clashes.isEmpty    { errors.append(LogicalClashError(clashes))  }
        
        return output
    }
    
    @discardableResult
    func check(
        _ candidate: PossibleError,
        _ checked: [PossibleError],
        _ duplicates: inout ErrorDictionary,
        _ clashes: inout ErrorDictionary
    ) -> Bool {
        if let existing = checked.first(where: { areDuplicates($0, candidate) }) {
            addErrorCandidate(existing: existing, current: candidate, to: &duplicates)
            return false
        }
        
        if let existing = checked.first(where: { areClashes($0, candidate) }) {
            addErrorCandidate(existing: existing, current: candidate, to: &clashes)
            return false
        }
        
        return true
    }
    
    func validate() -> [Error] {
        errors
    }
}

final class LazyTableNode: TableNodeProtocol {
    var rest: [any Node<DefineNode.Output>]
    var errors: [Error] = []
    
    init(rest: [any Node<DefineNode.Output>] = []) {
        self.rest = rest
    }
    
    func areDuplicates(_ lhs: PossibleError, _ rhs: PossibleError) -> Bool {
        if (lhs.state, lhs.pr, lhs.event, lhs.nextState) ==
            (rhs.state, rhs.pr, rhs.event, rhs.nextState) {
            return true
        }
        
        if (lhs.state, lhs.event, lhs.nextState) == (rhs.state, rhs.event, rhs.nextState) {
            func sortedPredicates(_ pe: PossibleError) -> [AnyPredicate] {
                pe.1.predicates.sorted { String(describing: $0) > String(describing: $1) }
            }
            
            var haveOnlyUniqueTypes: Bool {
                let lhsPredicateTypes = Set(lhsPredicates.map(\.type))
                let rhsPredicateTypes = Set(rhsPredicates.map(\.type))
                return lhsPredicateTypes.intersection(rhsPredicateTypes).isEmpty
            }
            
            var haveDuplicateValues: Bool {
                !Set(lhsPredicates).intersection(Set(rhsPredicates)).isEmpty
            }
            
            let lhsPredicates = sortedPredicates(lhs)
            let rhsPredicates = sortedPredicates(rhs)
            
            guard lhsPredicates.count == rhsPredicates.count else {
                return false
            }

            if haveOnlyUniqueTypes || haveDuplicateValues {
                return true
            }
        }
        
        return false
    }
    
    
    func _combinedWithRest(
        _ rest: [DefineNode.Output],
        duplicates: inout ErrorDictionary,
        clashes: inout ErrorDictionary
    ) -> [Output] {
        func checkAndAppend(
            _ dno: DefineNode.Output,
            pr: PredicateResult,
            result: inout [TableNodeOutput]
        ) {
            let outputTuple = outputComponents(dno, pr: pr)
            let candidate = outputTuple.candidate
            check(candidate, checked, &duplicates, &clashes)
            checked.append(candidate)
            result.append(outputTuple.output)
        }
        
        var checked = [PossibleError]()
        
        let output = rest.reduce(into: [Output]()) { result, dno in
            let allPredicateCombinations = dno.match.allPredicateCombinations([])
            
            guard !allPredicateCombinations.isEmpty else {
                checkAndAppend(dno, pr: PredicateResult(), result: &result)
                return
            }
           
            allPredicateCombinations.forEach {
                checkAndAppend(dno, pr: $0, result: &result)
            }
        }
        
        return output
    }
}

final class PreemptiveTableNode: TableNodeProtocol {
    var rest: [any Node<DefineNode.Output>]
    var errors: [Error] = []
    
    init(rest: [any Node<DefineNode.Output>] = []) {
        self.rest = rest
    }
    
    func areDuplicates(_ lhs: PossibleError, _ rhs: PossibleError) -> Bool {
        (lhs.state, lhs.pr, lhs.event, lhs.nextState) ==
        (rhs.state, rhs.pr, rhs.event, rhs.nextState)
    }
    
    func _combinedWithRest(
        _ rest: [DefineNode.Output],
        duplicates: inout ErrorDictionary,
        clashes: inout ErrorDictionary
    ) -> [Output] {
        var checked = [PossibleError]()
        var rankedDuplicates = ErrorDictionary()

        func areDuplicates(_ lhs: PossibleError, _ rhs: Output) -> Bool {
            (lhs.state, lhs.pr, lhs.event, lhs.nextState) ==
            (rhs.state, rhs.pr, rhs.event, rhs.nextState)
        }
        
        func areRankedDuplicates(_ lhs: PossibleError, _ rhs: PossibleError) -> Bool {
            (lhs.state, lhs.pr.predicates, lhs.event, lhs.nextState) ==
            (rhs.state, rhs.pr.predicates, rhs.event, rhs.nextState) &&
            lhs.pr != rhs.pr
        }
        
        let combinations = {
            let matches = rest.map(\.match)
            let anys = matches.map(\.matchAny)
            let alls = matches.map(\.matchAll)
            return (alls + anys).flattened.combinationsOfAllCases
        }()
        
        func checkAndAppend(
            _ dno: DefineNode.Output,
            pr: PredicateResult,
            result: inout [TableNodeOutput],
            check: (OutputTuple) -> ()
        ) {
            let outputTuple = outputComponents(dno, pr: pr)
            check(outputTuple)
            checked.append(outputTuple.candidate)
            result.append(outputTuple.output)
        }
        
        let output = rest.reduce(into: [Output]()) { result, dno in
            let allPredicateCombinations = dno.match.allPredicateCombinations(combinations)
            
            guard !allPredicateCombinations.isEmpty else {
                checkAndAppend(dno, pr: PredicateResult(), result: &result) {
                    check($0.candidate, checked, &duplicates, &clashes)
                }
                return
            }
            
            allPredicateCombinations.forEach {
                checkAndAppend(dno, pr: $0, result: &result) { tuple in
                    let candidate = tuple.candidate
                    
                    guard
                        check(candidate, checked, &duplicates, &clashes),
                        let existing = checked.first(
                            where: { areRankedDuplicates($0, candidate) }
                        )
                    else { return }
                    
                    rankedDuplicates[tuple.key] = rankedDuplicates[tuple.key] ?? [] + (
                        existing.pr.rank > candidate.pr.rank
                        ? [candidate]
                        : [existing]
                    )
                }
            }
        }
        
        return output.filter { tno in
            !rankedDuplicates.values.flattened.contains {
                areDuplicates($0, tno)
            }
        }
    }
}

extension PredicateResult {
    init() {
        predicates = []
        rank = 0
    }
}
