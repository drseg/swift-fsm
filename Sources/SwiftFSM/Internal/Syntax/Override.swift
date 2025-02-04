public extension Internal {
    struct Override {
        public func callAsFunction(
            @Internal.MWTABuilder _ block: @Sendable () -> [MWTA]
        ) -> [MWTA] {
            return block().asOverrides()
        }
    }
}

extension [Internal.MWTA] {
    func asOverrides() -> Self {
        (map(\.node) as? [OverridableNode])?.forEach {
            $0.isOverride = true
        }
        return self
    }
}
