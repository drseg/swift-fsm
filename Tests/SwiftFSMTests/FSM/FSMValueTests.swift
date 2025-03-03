import Testing
import Foundation
@testable import SwiftFSM

final class FSMValueTests: @unchecked Sendable {
    let vAny = FSMValue<String>.any
    let v1 = FSMValue.some("1")
    let v2 = FSMValue.some("2")

    @Test func value() {
        #expect(vAny.wrappedValue == nil)
        #expect(v1.wrappedValue == "1")
        #expect(v2.wrappedValue == "2")
    }
    
    @Test func throwingValue() {
        #expect(performing: {
            try vAny.throwingWrappedValue(#function)
        }, throws: { e in
            e.localizedDescription ==
            "FSMValue<String>.any has no value - the operation \(#function) is invalid."
        })
        
        #expect(throws: Never.self, performing: {
            try v1.throwingWrappedValue("")
        })
        
        #expect(v1.unsafeWrappedValue() == "1")
    }

    class ThrowerTest: Throwing {
        var isComplete = false
        var caller = ""
        
        func `throw`(instance: String, function: String) throws -> Never {
            caller = function
            isComplete = true
            repeat { RunLoop.current.run() } while true
        }
        
        @MainActor
        @Test func throwCallsThrowerWithFunctionName() async {
            FSMValue<Int>.setThrower(self)
            defer { FSMValue<Int>.resetThrower() }
            
            Task.detached {
                let _ = FSMValue<String>.any.unsafeWrappedValue()
            }
            
            while isComplete == false { }
            #expect(#function == caller)
        }
    }

    @Test func iIsSome() {
        #expect(!vAny.isSome)
        #expect(v1.isSome)
    }

    @Test func equality() {
        #expect(vAny == vAny)
        #expect(vAny == v1)
        #expect(vAny == v2)
        #expect(v1 == v1)
        #expect(v2 == v2)

        #expect(v1 != v2)
    }

    @Test func ConvenienceEquatable() {
        #expect(v1 == "1")
        #expect(v1 != "2")
        #expect("1" == v1)
        #expect("2" != v1)
    }

    @Test func convenienceComparable() {
        #expect((.any > "1") == false)
        #expect(v2 > "1")

        #expect((.any < "1") == false)
        #expect((v2 < "1") == false)

        #expect((.any <= "1") == false)
        #expect((v2 <= "1") == false)

        #expect((.any >= "1") == false)
        #expect(v1 >= "1")

        #expect((.any > "1") == false)
        #expect((v1 > "1") == false)

        #expect((.any <= "1") == false)
        #expect(v1 <= "1")

        #expect(("1" < .any) == false)
        #expect("1" < v2)

        #expect(("1" > .any) == false)
        #expect(("1" > v2) == false)

        #expect(("1" >= .any) == false)
        #expect(("1" >= v2) == false)

        #expect(("1" <= .any) == false)
        #expect("1" <= v1)

        #expect(("1" < .any) == false)
        #expect(("1" < v1) == false)

        #expect(("1" >= .any) == false)
        #expect("1" >= v1)
    }

    @Test func stringLiteral() {
        let s: FSMValue<String> = "1"
        let us: FSMValue<String> = .init(unicodeScalarLiteral: "1")
        let egc: FSMValue<String> = .init(extendedGraphemeClusterLiteral: "1")

        #expect(s == "1")
        #expect(us == "1")
        #expect(egc == "1")

        #expect(s + "1" == "11")
        #expect("1" + s == "11")
    }

    func assertEqual<T>(
        _ input: FSMValue<T>,
        _ expected: FSMValue<T>,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(input == expected, sourceLocation: location)
    }
    
    @Test func intLiteral() {
        let i8: FSMValue<Int8> = 1
        let i16: FSMValue<Int16> = 1
        let i32: FSMValue<Int32> = 1
        let i64: FSMValue<Int64> = 1
        let i: FSMValue<Int> = 1
        
        assertEqual(1, i8)
        assertEqual(1, i16)
        assertEqual(1, i32)
        assertEqual(1, i64)
        assertEqual(1, i)
    }
    
    @Test func floatLiteral() {
        let f: FSMValue<Float> = 1.0
        let f32: FSMValue<Float32> = 1.0
        let f64: FSMValue<Float64> = 1.0
        let d: FSMValue<Double> = 1.0
        
        assertEqual(1.0, f)
        assertEqual(1.0, f32)
        assertEqual(1.0, f64)
        assertEqual(1.0, d)
    }

    @Test func arrayLiteralAndAccess() {
        let a1: FSMValue<[String]> = ["cat", "cat"]

        assertEqual(a1, ["cat", "cat"])
        #expect(a1[0] == "cat")
        #expect(a1.first == "cat")
        #expect(a1.allSatisfy { $0 == "cat" })
        #expect(a1.index(after: 0) == 1)
        #expect(a1.index(before: 1) == 0)
    }

    @Test func dictionaryLiteralAndAccess() {
        let d1: FSMValue<[String: String]> = ["cat": "fish"]

        #expect(d1["cat"] == "fish")
        #expect(d1["bat"] == nil)
        #expect(d1["bat", default: "cat"] == "cat")
    }

    @Test func boolLiteral() {
        let b: FSMValue<Bool> = true
        #expect(b == true)
    }

    @Test func nilLiteral() {
        let optional: FSMValue<Bool?> = nil
        assertEqual(optional, nil)
    }

    @Test func additionSubtraction() {
        let i: FSMValue<Int> = 1
        let d: FSMValue<Double> = 1.0

        #expect(d + 1 == 2)
        #expect(i + 1 == 2)

        #expect(1 + d == 2)
        #expect(1 + i == 2)

        #expect(d - 1 == 0)
        #expect(i - 1 == 0)

        #expect(1 - d == 0)
        #expect(1 - i == 0)
    }

    @Test func multiplicationDivision() {
        let i: FSMValue<Int> = 1
        let d: FSMValue<Double> = 1.0

        #expect(d * 2 == 2)
        #expect(i * 2 == 2)

        #expect(2 * d == 2)
        #expect(2 * i == 2)

        #expect(d / 2 == 0.5)
        #expect(i / 2 == 0)

        #expect(2 / d == 2)
        #expect(2 / i == 2)
    }

    @Test func modulus() {
        let i: FSMValue<Int> = 1

        #expect(i % 2 == 1)
        #expect(2 % i == 0)
    }

    @Test func interpolation() {
        #expect("\(v1)" == "1")
        #expect("\(FSMValue.some(1))" == "1")
    }
}

struct EventWithValueTests {
    enum Event1: EventWithValues {
        case withValue(FSMValue<String>), withoutValue
    }
    
    struct Event2: EventWithValues {
        static let a: FSMValue<Int> = 1
        static let b: FSMValue<Int> = 2
    }

    let e1 = Event1.withValue(.some("1"))
    let e2 = Event1.withValue(.some("2"))
    
    let e3 = Event2.a
    let e4 = Event2.b
    
    let eAny = Event1.withValue(.any)
    let eNull = Event1.withoutValue

    @Test func equality() {
        #expect(e1 == e1)
        #expect(e1 == eAny)
        #expect(e3 == e3)

        #expect(e1 != e2)
        #expect(e1 != eNull)
        #expect(e3 != e4)
        #expect(eAny != eNull)
    }

    @Test func hashability() {
        let events = [eNull: 1, e1: 2]
        let events2 = [e3: 3]
        
        #expect(events2[e3] == 3)
        #expect(events2[e4] != 3)
        
        #expect(events[e1] == 2)
        #expect(events[e2] == nil)
        #expect(events[eAny] == 2)
        #expect(events[eNull] == 1)
    }
}
