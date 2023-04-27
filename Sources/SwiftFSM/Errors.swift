import Foundation

struct SwiftFSMError: LocalizedError, CustomStringConvertible {
    let errors: [Error]
    var description: String { localizedDescription }
    
    public var errorDescription: String? {
        String {
            ""
            "- SwiftFSM Errors -"
            ""
            "\(errors.count) errors were found:"
            ""
            errors.map { $0.localizedDescription }.joined(separator: "\n")
            ""
            "- End -"
        }
    }
}

class MatchError: Error {
    let predicates: [AnyPredicate]
    let files: [String]
    let lines: [Int]
    
    required init<C: Collection>(
        predicates: C,
        files: [String],
        lines: [Int]
    ) where C.Element == AnyPredicate {
        self.predicates = Array(predicates)
        self.files = files
        self.lines = lines
    }
    
    func append(files: [String], lines: [Int]) -> Self {
        .init(predicates: predicates,
              files: self.files + files,
              lines: self.lines + lines)
    }
    
    func duplicates(_ keypath: KeyPath<AnyPredicate, String>) -> String {
        let strings = predicates.map { $0[keyPath: keypath] }
        return Set(strings.filter { s in strings.filter { s == $0 }.count > 1 })
            .map { [$0] }
            .reduce([], +)
            .sorted()
            .joined(separator: ", ")
    }
    
    func predicatesString(separator: String) -> String {
        predicates
            .map(\.description)
            .sorted()
            .joined(separator: separator)
    }
    
    var filesAndLines: String {
        zip(files, lines).reduce([]) {
            $0 + [("file \($1.0.name), line \($1.1)")]
        }.joined(separator: "\n")
    }
    
    var duplicatesList: String {
        String {
            if files.count > 1 {
                "This combination was formed by AND-ing 'matching' statements at:"
                filesAndLines
            } else {
                "This combination was found in a 'matching' statement at \(filesAndLines)"
            }
        }
    }
}

class DuplicateMatchTypes: MatchError, LocalizedError {
    var firstLine: String {
        String {
            let dupes = duplicates(\.type)
            let predicates = predicatesString(separator: " AND ")
            
            let typesAppear = dupes.count > 1
            ? "types \(dupes) appear"
            : "type \(dupes) appears"
            
            "'matching(\(predicates))' is ambiguous - \(typesAppear) multiple times"
        }
    }
    
    public var errorDescription: String? {
        String {
            firstLine
            duplicatesList
        }
    }
}

class DuplicateAnyValues: MatchError, LocalizedError {
    public var errorDescription: String? {
        String {
            let dupes = duplicates(\.description)
            let predicates = predicatesString(separator: " OR ")
            "'matching(\(predicates))' contains multiple instances of \(dupes)"
            duplicatesList
        }
    }
}

class ConflictingAnyTypes: MatchError, LocalizedError {
    var errorDescription: String? {
        String {
            let predicates = predicatesString(separator: " OR ")
            
            "'matching(\(predicates))' is ambiguous - 'OR' values must be the same type"
            "This combination was found in a 'matching' statement at \(filesAndLines)"
        }
    }
}

class DuplicateAnyAllValues: MatchError, LocalizedError {
    public var errorDescription: String? {
        String {
            let dupes = duplicates(\.description)
            if files.count > 1 {
                "When combined, 'matching' statements at:"
                filesAndLines
                "...contain multiple instances of \(dupes)"
            } else {
                "'matching' statement at \(filesAndLines) contains multiple instances of \(dupes)"
            }
        }
    }
}

struct EmptyBuilderError: LocalizedError, Equatable {
    let caller: String
    let file: String
    let line: Int
    
    init(caller: String = #function, file: String, line: Int) {
        self.caller = String(caller.prefix { $0 != "(" })
        self.file = file
        self.line = line
    }
    
    public var errorDescription: String? {
        "Empty @resultBuilder block passed to '\(caller)' in \(file.name) at line \(line)"
    }
}

struct EmptyTableError: LocalizedError {
    public var errorDescription: String? {
        "FSM tables must have at least one 'define' statement in them"
    }
}

struct NSObjectError: LocalizedError {
    public var errorDescription: String? {
        String {
            "'State' and 'Event' types cannot:"
            ""
            "- Inherit from NSObject"
            "- Hold properties that inherit from NSObject'"
            ""
            "NSObject hashes by object id, leading to unintended FSM behaviour"
        }
    }
}

struct TableAlreadyBuiltError: LocalizedError {
    let file: String
    let line: Int
    
    var errorDescription: String? {
        "Duplicate call to method buildTable in file \(file.name) at line \(line)"
    }
}

protocol ValidationError: LocalizedError {}
extension ValidationError {
    func description<K: Hashable, V: Collection>(
        _ header: String,
        _ dict: [K: V],
        @StringBuilder _ eachGroup: (V.Element) -> [String]
    ) -> String {
        String {
            header + " (total: \(dict.count)):"
            for (i, e) in dict.enumerated() {
                ""
                eachGroupDescription("Group \(i + 1):", e, eachGroup)
            }
        }
    }
    
    func eachGroupDescription<K: Hashable, V: Collection>(
        _ header: String,
        _ group: (K, V),
        @StringBuilder _ eachGroup: (V.Element) -> [String]
    ) -> String {
        String {
            header
            ""
            for (i, e) in group.1.enumerated() {
                eachGroup(e)
                if i < group.1.count - 1 {
                    ""
                }
            }
        }
    }
}

extension SemanticValidationNode.DuplicatesError: ValidationError {
    var errorDescription: String? {
        description("The FSM table contains duplicate groups", duplicates) {
            $0.state.defineDescription
            $0.match.errorDescription
            $0.event.whenDescription
            $0.nextState.thenDescription
        }
    }
}

extension SemanticValidationNode.ClashError: ValidationError {
    var errorDescription: String? {
        description("The FSM table contains logical clash groups", clashes) {
            $0.state.defineDescription
            $0.match.errorDescription
            $0.event.whenDescription
        }
    }
}

extension SemanticValidationNode.OverrideError {
    func describeOverride(_ o: IntermediateIO) -> String {
        String {
            let define = override.state.defineDescription + " {"
            let matching = override.match.errorDescription + " | "
            let when = override.event.whenDescription + " | "
            let then = override.nextState.thenDescription + " }"
            
            define
            "   override { " + matching + when + then
            "}"
        }
    }
}

extension SemanticValidationNode.NothingToOverride: LocalizedError {
    var errorDescription: String? {
        String {
            "Nothing To Override: the statement..."
            ""
            describeOverride(override)
            ""
            "...does not override anything"
        }
    }
}

extension SemanticValidationNode.OverrideOutOfOrder: LocalizedError {
    var errorDescription: String? {
        String {
            "Overrides Out of Order: SuperState statement..."
            ""
            describeOverride(override)
            ""
            "...is attempting to override the following child statements:"
            for child in outOfOrder {
                ""
                describeOverride(child)
            }
        }
    }
}

extension EagerMatchResolvingNode.ImplicitClashesError: ValidationError {
    var errorDescription: String? {
        String {
            "The FSM table contains implicit logical clashes (total: \(clashes.count))"
            for (i, clashGroup) in clashes.sorted(by: {
                $0.key.state.line < $1.key.state.line
            }).enumerated() {
                let predicates = clashGroup.key.predicates.reduce([]) {
                    $0 + [$1.description]
                }.sorted().joined(separator: " AND ")
                
                ""
                "Multiple clashing statements imply the same predicates (\(predicates))"
                ""
                eachGroupDescription("Context \(i + 1):", clashGroup) { c in
                    c.state.defineDescription
                    c.match.errorDescription
                    c.event.whenDescription
                    c.nextState.thenDescription
                }
            }
        }
    }
}

extension Match {
    var asArray: [Match] {
        [originalSelf?.removingNext ?? removingNext] + (next?.asArray ?? [])
    }
    
    var removingNext: Match {
        Match(any: matchAny, all: matchAll, file: file, line: line)
    }
    
    var errorDescription: String {
        guard condition == nil else {
            return "condition(() -> Bool) @\(file.name): \(line)"
        }
        
        let or = matchAny.reduce([String]()) { result, predicates in
            let firstPredicateString = predicates.first!.description
            
            return result + [predicates.dropFirst().reduce(firstPredicateString) {
                "(\($0) OR \($1))"
            }]
        }.joined(separator: " AND ")
        
        let and = matchAll.map(\.description).joined(separator: " AND ")
        
        var summary: String
        switch (matchAll.isEmpty, matchAny.isEmpty) {
        case (true, true): summary = ""
        case (true, false): summary = "matching(\(or))"
        case (false, true): summary = "matching(\(and))"
        case (false, false): summary = "matching(\(or) AND \(and))"
        }
        
        let components = asArray
        guard components.count > 1 else {
            return summary + (summary.isEmpty ? "matching()" : " @\(file.name): \(line)")
        }
        
        return String {
            summary
            "  formed by combining:"
            components.reduce([]) { $0 + ["    - " + $1.errorDescription] }.joined(separator: "\n")
        }
    }
}

extension AnyTraceable {
    var fileAndLine: String {
        "@\(file.name): \(line)"
    }
    
    var defineDescription: String { description("define") }
    var whenDescription:   String { description("when")   }
    var thenDescription:   String { description("then")   }
    
    func description(_ prefix: String) -> String {
        prefix + "(\(base)) " + fileAndLine
    }
}

extension ResultBuilder {
    static func buildEither(first: [T]) -> [T] { first }
    static func buildEither(second: [T]) -> [T] { second }
    static func buildOptional(_ component: [T]?) -> [T] { component ?? [] }
    static func buildArray(_ components: [[T]]) -> [T] { components.flattened }
}

@resultBuilder struct StringBuilder: ResultBuilder { typealias T = String }
extension String {
    init(@StringBuilder _ b: () -> [String]) {
        self.init(b().joined(separator: "\n"))
    }
}

extension String {
    var name: String {
        split(separator: "/").map(String.init).last ?? self
    }
}
