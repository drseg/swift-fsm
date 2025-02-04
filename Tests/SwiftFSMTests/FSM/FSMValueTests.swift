import XCTest
@testable import SwiftFSM

final class FSMValueTests: XCTestCase, @unchecked Sendable {
    let vAny = FSMValue<String>.any
    let v1 = FSMValue.some("1")
    let v2 = FSMValue.some("2")

    override func tearDown() {
        FSMValue<Int>.resetThrower()
    }

    func testValue() {
        XCTAssertEqual(vAny.wrappedValue, nil)
        XCTAssertEqual(v1.wrappedValue, "1")
        XCTAssertEqual(v2.wrappedValue, "2")
    }

    func testThrowingValue() {
        XCTAssertThrowsError(try vAny.throwingWrappedValue(#function)) {
            XCTAssertEqual(
                $0.localizedDescription,
                "FSMValue<String>.any has no value - the operation \(#function) is invalid."
            )
        }
        XCTAssertNoThrow(try v1.throwingWrappedValue(""))
        XCTAssertEqual(v1.unsafeWrappedValue(), "1")
    }

    @MainActor
    func testUnsafeWrappedValuePassesCallersNameToError() throws {
        struct Thrower: Throwing {
            let expectedFunction: String
            let expectation: XCTestExpectation
            
            init(expectedFunction: String = #function, expectation: XCTestExpectation) {
                self.expectedFunction = expectedFunction
                self.expectation = expectation
            }
            
            func `throw`(instance: String, function: String) throws -> Never {
                XCTAssertEqual(function, expectedFunction)
                expectation.fulfill()
                repeat { RunLoop.current.run() } while true
            }
        }
        
        FSMValue<Int>.setThrower(Thrower(expectation: expectation(description: "")))
        DispatchQueue.global().async {
            let _ = self.vAny.unsafeWrappedValue()
        }
        waitForExpectations(timeout: 0.1)
    }

    func testIsSome() {
        XCTAssertFalse(vAny.isSome)
        XCTAssertTrue(v1.isSome)
    }

    func testEquality() {
        XCTAssertEqual(vAny, vAny)
        XCTAssertEqual(vAny, v1)
        XCTAssertEqual(vAny, v2)
        XCTAssertEqual(v1, v1)
        XCTAssertEqual(v2, v2)

        XCTAssertNotEqual(v1, v2)
    }

    func testConvenienceEquatable() {
        XCTAssertTrue(v1 == "1")
        XCTAssertTrue(v1 != "2")
        XCTAssertFalse(v1 != "1")
        XCTAssertFalse(v1 == "2")

        XCTAssertTrue("1" == v1)
        XCTAssertTrue("2" != v1)
        XCTAssertFalse("1" != v1)
        XCTAssertFalse("2" == v1)
    }

    func testConvenienceComparable() {
        XCTAssertFalse(.any > "1")
        XCTAssertTrue(v2 > "1")

        XCTAssertFalse(.any < "1")
        XCTAssertFalse(v2 < "1")

        XCTAssertFalse(.any <= "1")
        XCTAssertFalse(v2 <= "1")

        XCTAssertFalse(.any >= "1")
        XCTAssertTrue(v1 >= "1")

        XCTAssertFalse(.any > "1")
        XCTAssertFalse(v1 > "1")

        XCTAssertFalse(.any <= "1")
        XCTAssertTrue(v1 <= "1")

        XCTAssertFalse("1" < .any)
        XCTAssertTrue("1" < v2)

        XCTAssertFalse("1" > .any)
        XCTAssertFalse("1" > v2)

        XCTAssertFalse("1" >= .any)
        XCTAssertFalse("1" >= v2)

        XCTAssertFalse("1" <= .any)
        XCTAssertTrue("1" <= v1)

        XCTAssertFalse("1" < .any)
        XCTAssertFalse("1" < v1)

        XCTAssertFalse("1" >= .any)
        XCTAssertTrue("1" >= v1)
    }

    func testStringLiteral() {
        let s: FSMValue<String> = "1"
        let us: FSMValue<String> = .init(unicodeScalarLiteral: "1")
        let egc: FSMValue<String> = .init(extendedGraphemeClusterLiteral: "1")

        XCTAssertEqual(s, "1")
        XCTAssertEqual(us, "1")
        XCTAssertEqual(egc, "1")

        XCTAssertEqual(s + "1", "11")
        XCTAssertEqual("1" + s, "11")
    }

    func testIntLiteral() {
        let i8: FSMValue<Int8> = 1
        let i16: FSMValue<Int16> = 1
        let i32: FSMValue<Int32> = 1
        let i64: FSMValue<Int64> = 1
        let i: FSMValue<Int> = 1

        XCTAssertEqual(1, i8)
        XCTAssertEqual(1, i16)
        XCTAssertEqual(1, i32)
        XCTAssertEqual(1, i64)
        XCTAssertEqual(1, i)
    }

    func testFloatLiteral() {
        let f: FSMValue<Float> = 1.0
        let f32: FSMValue<Float32> = 1.0
        let f64: FSMValue<Float64> = 1.0
        let d: FSMValue<Double> = 1.0

        XCTAssertEqual(1.0, f)
        XCTAssertEqual(1.0, f32)
        XCTAssertEqual(1.0, f64)
        XCTAssertEqual(1.0, d)
    }

    func testArrayLiteralAndAccess() {
        let a1: FSMValue<[String]> = ["cat", "cat"]

        XCTAssertEqual(a1, ["cat", "cat"])
        XCTAssertEqual(a1[0], "cat")
        XCTAssertEqual(a1.first, "cat")
        XCTAssertTrue(a1.allSatisfy { $0 == "cat" })
        XCTAssertEqual(a1.index(after: 0), 1)
        XCTAssertEqual(a1.index(before: 1), 0)
    }

    func testDictionaryLiteralAndAccess() {
        let d1: FSMValue<[String: String]> = ["cat": "fish"]

        XCTAssertEqual(d1["cat"], "fish")
        XCTAssertEqual(d1["bat"], nil)
        XCTAssertEqual(d1["bat", default: "cat"], "cat")
    }

    func testBoolLiteral() {
        let b: FSMValue<Bool> = true
        XCTAssertEqual(true, b)
    }

    func testNilLiteral() {
        let optional: FSMValue<Bool?> = nil
        XCTAssertEqual(optional, nil)
    }

    func testAdditionSubtraction() {
        let i: FSMValue<Int> = 1
        let d: FSMValue<Double> = 1.0

        XCTAssertEqual(d + 1, 2)
        XCTAssertEqual(i + 1, 2)

        XCTAssertEqual(1 + d, 2)
        XCTAssertEqual(1 + i, 2)

        XCTAssertEqual(d - 1, 0)
        XCTAssertEqual(i - 1, 0)

        XCTAssertEqual(1 - d, 0)
        XCTAssertEqual(1 - i, 0)
    }

    func testMultiplicationDivision() {
        let i: FSMValue<Int> = 1
        let d: FSMValue<Double> = 1.0

        XCTAssertEqual(d * 2, 2)
        XCTAssertEqual(i * 2, 2)

        XCTAssertEqual(2 * d, 2)
        XCTAssertEqual(2 * i, 2)

        XCTAssertEqual(d / 2, 0.5)
        XCTAssertEqual(i / 2, 0)

        XCTAssertEqual(2 / d, 2)
        XCTAssertEqual(2 / i, 2)
    }

    func testModulus() {
        let i: FSMValue<Int> = 1

        XCTAssertEqual(i % 2, 1)
        XCTAssertEqual(2 % i, 0)
    }

    func testInterpolation() {
        XCTAssertEqual("\(v1)", "1")
        XCTAssertEqual("\(FSMValue.some(1))", "1")
    }
}

final class EventWithValueTests: XCTestCase {
    enum Event: EventWithValues {
        case withValue(FSMValue<String>), withoutValue
    }

    let e1 = Event.withValue(.some("1"))
    let e2 = Event.withValue(.some("2"))
    let eAny = Event.withValue(.any)
    let eNull = Event.withoutValue

    func testEquality() {
        XCTAssertEqual(e1, e1)
        XCTAssertEqual(e1, eAny)

        XCTAssertNotEqual(e1, e2)
        XCTAssertNotEqual(e1, eNull)
        XCTAssertNotEqual(eAny, eNull)
    }

    func testHashability() {
        let events = [eNull: 1, e1: 2]

        XCTAssertEqual(events[e1], 2)
        XCTAssertEqual(events[e2], nil)
        XCTAssertEqual(events[eAny], 2)
        XCTAssertEqual(events[eNull], 1)
    }
}
