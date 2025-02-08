public extension Syntax {
    struct Override {
        public func callAsFunction(
            @MWTABuilder _ group: () -> [MatchingWhenThenActions]
        ) -> [MatchingWhenThenActions] {
            return group().asOverrides()
        }
    }
}

extension [Syntax.MatchingWhenThenActions] {
    func asOverrides() -> Self {
        (map(\.node) as? [OverridableNode])?.forEach {
            $0.isOverride = true
        }
        return self
    }
}
