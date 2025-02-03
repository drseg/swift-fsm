import XCTest
@testable import SwiftFSM

final class AnyTraceableTests: SyntaxNodeTests {
    func testTraceableEquality() {
        let t1 = randomisedTrace("cat")
        let t2 = randomisedTrace("cat")
        let t3 = randomisedTrace("bat")
        let t4: AnyTraceable = "cat"
        
        XCTAssertEqual(t1, t2)
        XCTAssertEqual(t1, t4)
        XCTAssertNotEqual(t1, t3)
    }
    
    func testTraceableHashing() async {
        var randomCat: AnyTraceable { randomisedTrace("cat") }
        
        for _ in 0...1000 {
            let dict = [randomCat: randomCat]
            XCTAssertEqual(dict[randomCat], randomCat)
        }
    }
    
    func testTraceableDescription() {
        XCTAssertEqual(s1.description, "S1")
    }
    
    func testBangsOptionals() {
        let c1: String? = "cat"
        
        let t = AnyTraceable(c1, file: "", line: 0)
        let c2 = t.base
        
        XCTAssertTrue(String(describing: c1).contains("Optional"))
        XCTAssertFalse(String(describing: c2).contains("Optional"))
    }
}
