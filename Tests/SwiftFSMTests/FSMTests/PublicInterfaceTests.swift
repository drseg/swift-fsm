import XCTest
import SwiftFSM

final class PublicInterfaceTests: XCTestCase {
    final class MyClass: SyntaxBuilder {
        enum State { case locked, unlocked }
        enum Event { case coin, pass }
        
        let fsm = FSM<State, Event>(initialState: .locked)
        
        init() throws {
            try fsm.buildTable {
                define(.locked) {
                    when(.coin) | then(.unlocked) | unlock
                    when(.pass) | then(.locked)   | alarm
                }
                
                define(.unlocked) {
                    when(.coin) | then(.unlocked) | thankyou
                    when(.pass) | then(.locked)   | lock
                }
            }
        }

        var callLog = [String]()

        func unlock()   { log() }
        func alarm()    { log() }
        func thankyou() { log() }
        func lock()     { log() }

        private func log(_ function: String = #function) {
            callLog.append(function)
        }
    }

    private var sut: MyClass!

    override func setUp() async throws {
        sut = try MyClass()
    }

    @MainActor
    private func handleEvents(_ events: MyClass.Event...) throws {
        try events.forEach(sut.fsm.handleEvent)
    }

    private func assertLog(_ expected: String..., line: UInt = #line) {
        XCTAssertEqual(sut.callLog, expected, line: line)
    }

    @MainActor
    func testPublicInterface() throws {
        try handleEvents(.coin, .coin, .coin, .pass, .pass)
        assertLog("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
}
