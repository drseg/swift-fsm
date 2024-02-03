import XCTest
import SwiftFSM

@MainActor
final class PublicTests: XCTestCase {
    enum P: Predicate {
        case a
    }

    func assert(_ fsm: some FSMBase<Int, Int>, typeName: String, line: UInt = #line) {
        try? fsm.buildTable { }
        fsm.handleEvent(1)
        fsm.handleEvent(1, predicates: [P.a])
        fsm.handleEvent(1, predicates: P.a)
        fsm.handleEvent(1, predicates: P.a, P.a)
        XCTAssertEqual(typeName, "\(type(of: fsm))", line: line)
    }

    func testCanMakeEagerFSM() {
        let fsm = FSMFactory<_, Int>.makeEager(initialState: 1,
                                               actionsPolicy: .executeOnChangeOnly)
        assert(fsm, typeName: "FSM<Int, Int>")
    }

    func testCanMakeLazyFSM() {
        let fsm = FSMFactory<_, Int>.makeLazy(initialState: 1,
                                              actionsPolicy: .executeOnChangeOnly)
        assert(fsm, typeName: "LazyFSM<Int, Int>")
    }
}
