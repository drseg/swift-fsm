public extension Syntax {
    struct Override {
        public func callAsFunction(
            @MWTABuilder _ block: () -> [MWTA]
        ) -> [MWTA] {
            return block().asOverrides()
        }
    }
}

extension [Syntax.MWTA] {
    func asOverrides() -> Self {
        (map(\.node) as? [OverridableNode])?.forEach {
            $0.isOverride = true
        }
        return self
    }
}
