import Foundation

struct AnyTraceable: @unchecked Sendable {
    let base: AnyHashable
    let file: String
    let line: Int

    init<H: FSMHashable>(_ base: H?, file: String, line: Int) {
        self.base = base!
        self.file = file
        self.line = line
    }
}

extension AnyTraceable: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}
