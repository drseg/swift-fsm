import Testing
@testable import SwiftFSM

final class AnyTraceableTests: SyntaxNodeTests {
    @Test func traceableEquality() {
        let t1 = randomisedTrace("cat")
        let t2 = randomisedTrace("cat")
        let t3 = randomisedTrace("bat")
        let t4: AnyTraceable = "cat"
        
        #expect(t1 == t2)
        #expect(t1 == t4)
        #expect(t1 != t3)
    }
    
    @Test func traceableHashing() async {
        var randomCat: AnyTraceable { randomisedTrace("cat") }
        
        for _ in 0...1000 {
            let dict = [randomCat: randomCat]
            #expect(dict[randomCat] == randomCat)
        }
    }
    
    @Test func traceableDescription() {
        #expect(s1.description == "S1")
    }
    
    @Test func bangsOptionals() {
        let c1: String? = "cat"
        
        let t = AnyTraceable(c1, file: "", line: 0)
        let c2 = t.base
        
        #expect(String(describing: c1).contains("Optional"))
        #expect(!String(describing: c2).contains("Optional"))
    }
}
