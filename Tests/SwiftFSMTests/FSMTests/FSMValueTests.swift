import XCTest
//import SwiftFSMMacros
@testable import SwiftFSM

final class FSMValueTests: XCTestCase {
    let v1 = FSMValue<String>.any
    let v2 = FSMValue.some("1")
    let v3 = FSMValue.some("2")

    func testEquality() {
        XCTAssertEqual(v1, v1)
        XCTAssertEqual(v1, v2)
        XCTAssertEqual(v1, v3)
        XCTAssertEqual(v2, v2)
        XCTAssertEqual(v3, v3)

        XCTAssertNotEqual(v2, v3)
    }

    func testValue() {
        XCTAssertEqual(v1.wrappedValue, nil)
        XCTAssertEqual(v2.wrappedValue, "1")
        XCTAssertEqual(v3.wrappedValue, "2")
    }

    func testConvenienceEquatable() {
        XCTAssertTrue(v2 == "1")
        XCTAssertTrue(v2 != "2")
        XCTAssertFalse(v2 != "1")
        XCTAssertFalse(v2 == "2")

        XCTAssertTrue("1" == v2)
        XCTAssertTrue("2" != v2)
        XCTAssertFalse("1" != v2)
        XCTAssertFalse("2" == v2)
    }

    func testConvenienceComparable() {
        XCTAssertTrue(v3 > "1")
        XCTAssertFalse(v3 < "1")
        XCTAssertFalse(v3 <= "1")
        XCTAssertTrue(v2 >= "1")
        XCTAssertFalse(v2 > "1")
        XCTAssertTrue(v2 <= "1")

        XCTAssertTrue("1" < v3)
        XCTAssertFalse("1" > v3)
        XCTAssertFalse("1" >= v3)
        XCTAssertTrue("1" <= v2)
        XCTAssertFalse("1" < v2)
        XCTAssertTrue("1" >= v2)
    }
}

final class EventValueTests: XCTestCase {
    enum Event: EventValue {
        case first, second, any
    }

    func testEquality() {
        let e1 = Event.first
        let e2 = Event.second
        let e3 = Event.any

        XCTAssertEqual(e1, e1)
        XCTAssertEqual(e1, e3)
        XCTAssertEqual(e2, e2)
        XCTAssertEqual(e2, e3)

        XCTAssertNotEqual(e1, e2)
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
