import Foundation

protocol SVNKey: FSMHashable {
    init(_ input: SemanticValidationNode.Input)
}

class SemanticValidationNode: SyntaxNode {
    typealias DuplicatesDictionary = [DuplicatesKey: [Input]]
    typealias ClashesDictionary = [ClashesKey: [Input]]

    var rest: [any SyntaxNode<OverrideSyntaxDTO>]
    var errors: [Error] = []

    init(rest: [any SyntaxNode<Input>]) {
        self.rest = rest
    }

    func combinedWith(_ rest: [OverrideSyntaxDTO]) -> [OverrideSyntaxDTO] {
        var duplicates = DuplicatesDictionary()
        var clashes = ClashesDictionary()

        var output = rest.reduce(into: [Output]()) { result, row in
            func isDuplicate(_ lhs: Input) -> Bool {
                isError(lhs, keyType: DuplicatesKey.self)
            }

            func isClash(_ lhs: Input) -> Bool {
                isError(lhs, keyType: ClashesKey.self)
            }

            func isError<T: SVNKey>(_ lhs: Input, keyType: T.Type) -> Bool {
                let haveClashingValues = T.init(lhs) == T.init(row)
                let haveNoOverrides = !lhs.isOverride && !row.isOverride
                let haveOverrides = lhs.isOverride || row.isOverride
                let areSameOverrideGroup = lhs.overrideGroupID == row.overrideGroupID

                return haveClashingValues && (haveNoOverrides || haveOverrides && areSameOverrideGroup)
            }

            func add<T: SVNKey>(_ existing: Output, row: Output, to dict: inout [T: [Input]]) {
                let key = T(row)
                dict[key] = (dict[key] ?? [existing]) + [row]
            }

            if let dupe = result.first(where: isDuplicate) {
                add(dupe, row: row, to: &duplicates)
            } else if let clash = result.first(where: isClash) {
                add(clash, row: row, to: &clashes)
            }

            result.append(row)
        }

        if !duplicates.isEmpty {
            errors.append(DuplicatesError(duplicates: duplicates))
        }

        if !clashes.isEmpty {
            errors.append(ClashError(clashes: clashes))
        }

        output = implementOverrides(in: output)
        return errors.isEmpty ? output : []
    }

    private func implementOverrides(in output: [OverrideSyntaxDTO]) -> [OverrideSyntaxDTO] {
        var reverseOutput = Array(output.reversed())
        let overrides = reverseOutput.filter(\.isOverride)
        guard !overrides.isEmpty else { return output }

        var alreadyOverridden = [OverrideSyntaxDTO]()

        overrides.forEach { override in
            func isOverridden(_ candidate: OverrideSyntaxDTO) -> Bool {
                candidate.state == override.state &&
                candidate.descriptor == override.descriptor &&
                candidate.event == override.event
            }

            func implementOverrides() {
                func findOutOfPlaceOverrides() -> [OverrideSyntaxDTO]? {
                    let prefix = Array(reverseOutput.prefix(upTo: indexAfterOverride - 1))
                    let outOfPlaceOverrides = prefix.filter(isOverridden)
                    return outOfPlaceOverrides.isEmpty ? nil : outOfPlaceOverrides
                }

                func findSuffixFromOverride() -> [OverrideSyntaxDTO]? {
                    let suffix = Array(reverseOutput.suffix(from: indexAfterOverride))
                    return suffix.contains(where: isOverridden) ? suffix : nil
                }

                let indexAfterOverride = reverseOutput.firstIndex { $0 == override }! + 1

                if let outOfPlaceOverrides = findOutOfPlaceOverrides() {
                    errors.append(OverrideOutOfOrder(override, outOfPlaceOverrides)); return
                }

                guard var suffixFromOverride = findSuffixFromOverride() else {
                    errors.append(NothingToOverride(override)); return
                }

                suffixFromOverride.removeAll(where: isOverridden)
                reverseOutput.replaceSubrange(indexAfterOverride..., with: suffixFromOverride)
            }

            if !alreadyOverridden.contains(where: isOverridden) {
                alreadyOverridden.append(override)
                implementOverrides()
            }
        }

        return reverseOutput.reversed()
    }

    func findErrors() -> [Error] {
        errors
    }
}

extension SemanticValidationNode {
    struct DuplicatesError: Error {
        let duplicates: DuplicatesDictionary
    }

    struct ClashError: Error {
        let clashes: ClashesDictionary
    }

    class OverrideError: @unchecked Sendable, Error {
        let override: OverrideSyntaxDTO

        init(_ override: OverrideSyntaxDTO) {
            self.override = override
        }
    }

    final class OverrideOutOfOrder: OverrideError, @unchecked Sendable {
        let outOfOrder: [OverrideSyntaxDTO]

        init(_ override: OverrideSyntaxDTO, _ outOfOrder: [OverrideSyntaxDTO]) {
            self.outOfOrder = outOfOrder
            super.init(override)
        }
    }

    final class NothingToOverride: OverrideError, @unchecked Sendable { }

    struct DuplicatesKey: SVNKey {
        let state: AnyTraceable,
            match: MatchDescriptorChain,
            event: AnyTraceable,
            nextState: AnyTraceable

        init(_ input: Input) {
            state = input.state
            match = input.descriptor
            event = input.event
            nextState = input.nextState
        }
    }

    struct ClashesKey: SVNKey {
        let state: AnyTraceable,
            match: MatchDescriptorChain,
            event: AnyTraceable

        init(_ input: Input) {
            state = input.state
            match = input.descriptor
            event = input.event
        }
    }
}

extension OverrideSyntaxDTO: Equatable {
    static func == (lhs: OverrideSyntaxDTO, rhs: OverrideSyntaxDTO) -> Bool {
        lhs.state == rhs.state &&
        lhs.descriptor == rhs.descriptor &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState &&
        lhs.overrideGroupID == rhs.overrideGroupID &&
        lhs.isOverride == rhs.isOverride
    }
}
