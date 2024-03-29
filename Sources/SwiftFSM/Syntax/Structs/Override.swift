public extension Syntax {
    struct Override {
        public func callAsFunction(
            @Internal.MWTABuilder _ block: () -> [MWTA]
        ) -> [MWTA] {
            return block().asOverrides()
        }
    }
}

extension [MWTA] {
    func asOverrides() -> Self {
        (map(\.node) as? [OverridableNode])?.forEach {
            $0.isOverride = true
        }
        return self
    }
}
