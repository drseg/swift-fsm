import Testing
@testable import SwiftFSM

struct CombinationsTests {
    @Test(arguments: [
        (input: [], expected: []),
        (input: [[]], expected: []),
        (input: [[], []], expected: []),
        (input: [[1]], expected: [[1]]),
        (input: [[1, 2]], expected: [[1], [2]]),
        (input: [[1], [2]], expected: [[1, 2]]),
        (input: [[1], [2], [3]], expected: [[1, 2, 3]]),
        (input: [[1, 2], [3]], expected: [[1, 3], [2, 3]]),
        (input: [[1, 2], [3, 4]], expected: [[1, 3], [1, 4], [2, 3], [2, 4]])
    ])
    func combinations(input: [[Int]], expected: [[Int]]) {
        #expect(input.combinations() == expected)
    }
}
