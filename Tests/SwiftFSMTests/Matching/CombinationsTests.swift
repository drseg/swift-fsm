import XCTest
@testable import SwiftFSM

final class CombinationsTests: XCTestCase {
    func assertCombinations(of a: [[Int]], expected: [[Int]], line: UInt = #line) {
        XCTAssertEqual(expected, a.combinations(), line: line)
    }
    
    func testCombinations() {
        assertCombinations(of: [], expected: [])
        assertCombinations(of: [[]], expected: [])
        assertCombinations(of: [[], []], expected: [])
        assertCombinations(of: [[1]], expected: [[1]])
        assertCombinations(of: [[1, 2]], expected: [[1], [2]])
        assertCombinations(of: [[1], [2]], expected: [[1, 2]])
        assertCombinations(of: [[1], [2], [3]], expected: [[1, 2, 3]])
        assertCombinations(of: [[1, 2], [3]], expected: [[1, 3], [2, 3]])
        assertCombinations(of: [[1, 2], [3, 4]], expected: [[1, 3], [1, 4], [2, 3], [2, 4]])
    }
}
