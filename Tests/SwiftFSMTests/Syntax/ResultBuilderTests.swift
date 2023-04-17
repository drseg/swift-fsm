import XCTest
@testable import SwiftFSM

class ResultBuilderTests: XCTestCase {
    @resultBuilder
    struct Builder: ResultBuilder {
        typealias T = String
    }
    
    func build(@Builder s: () -> [String]) -> String {
        s().joined()
    }
    
    func testEmptyBuilder() {
        let s = build { }
        
        XCTAssertEqual("", s)
    }
    
    func testBuilderWithOneEmptyArgument() {
        let s = build { "" }
        
        XCTAssertEqual("", s)
    }
    
    func testBuilderWithOneArgument() {
        let s = build {
            "Cat"
        }
        
        XCTAssertEqual("Cat", s)
    }
    
    func testBuilderWithMultipleEmptyArguments() {
        let s = build {
            ""
            ""
        }
        
        XCTAssertEqual("", s)
    }
    
    func testBuilderWithMultipleArguments() {
        let s = build {
            "The "
            "cat "
            "sat "
            "on "
            "the "
            "mat"
        }
        
        XCTAssertEqual("The cat sat on the mat", s)
    }
    
    func testBuilderWithEmptyArrayArguent() {
        let s = build {
            []
        }
        
        XCTAssertEqual("", s)
    }
    
    func testBuilderWithArrayArgument() {
        let s = build {
            ["The ", "cat ", "sat ", "on ", "the ", "mat"]
        }
        
        XCTAssertEqual("The cat sat on the mat", s)
    }
    
    func testBuilderWithEmptyArrayArguents() {
        let s = build {
            []
            []
        }
        
        XCTAssertEqual("", s)
    }
    
    func testBuilderWithArrayArguments() {
        let s = build {
            ["The ", "cat ", "sat "]
            ["on ", "the ", "mat"]
        }
        
        XCTAssertEqual("The cat sat on the mat", s)
    }
}

