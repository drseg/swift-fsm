import Foundation

struct AnyTraceable {
    let base: AnyHashable
    let file: String
    let line: Int
    
    init<H: Hashable>(_ base: H?, file: String, line: Int) {
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
