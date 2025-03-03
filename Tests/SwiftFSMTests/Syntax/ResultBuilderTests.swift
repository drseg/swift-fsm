import Testing
@testable import SwiftFSM

class ResultBuilderTests {
    @resultBuilder
    struct Builder: ResultBuilder {
        typealias T = String
    }
    
    func build(@Builder s: () -> [String]) -> String {
        s().joined()
    }
    
    @Test func emptyBuilder() {
        let s = build { }
        
        #expect("" == s)
    }
    
    @Test func builderWithOneEmptyArgument() {
        let s = build { "" }
        
        #expect("" == s)
    }
    
    @Test func builderWithOneArgument() {
        let s = build {
            "Cat"
        }
        
        #expect("Cat" == s)
    }
    
    @Test func builderWithMultipleEmptyArguments() {
        let s = build {
            ""
            ""
        }
        
        #expect("" == s)
    }
    
    @Test func builderWithMultipleArguments() {
        let s = build {
            "The "
            "cat "
            "sat "
            "on "
            "the "
            "mat"
        }
        
        #expect("The cat sat on the mat" == s)
    }
    
    @Test func builderWithEmptyArrayArgument() {
        let s = build {
            []
        }
        
        #expect("" == s)
    }
    
    @Test func builderWithArrayArgument() {
        let s = build {
            ["The ", "cat ", "sat ", "on ", "the ", "mat"]
        }
        
        #expect("The cat sat on the mat" == s)
    }
    
    @Test func builderWithEmptyArrayArguments() {
        let s = build {
            []
            []
        }
        
        #expect("" == s)
    }
    
    @Test func builderWithArrayArguments() {
        let s = build {
            ["The ", "cat ", "sat "]
            ["on ", "the ", "mat"]
        }
        
        #expect("The cat sat on the mat" == s)
    }
}

