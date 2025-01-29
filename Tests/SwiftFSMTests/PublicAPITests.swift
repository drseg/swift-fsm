import XCTest
import SwiftFSM
// Do not use @testable here //

final class PublicAPITests: XCTestCase {
    final class SUT: SyntaxBuilder {
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
        
        func unlock() { logAction() }
        func alarm() { logAction() }
        func thankyou() { logAction() }
        func lock() { logAction() }
        
        var log = [String]()
        
        func logAction(_ f: String = #function) {
            log.append(f)
        }
    }
    
    @MainActor
    func testPublicAPI() throws {
        func assertLog(_ a: String..., line: UInt = #line) {
            XCTAssertEqual(sut.log, a, line: line)
        }
        
        let sut = try SUT()
        XCTAssert(sut.log.isEmpty)
        
        try sut.fsm.handleEvent(.coin)
        assertLog("unlock()")
        
        try sut.fsm.handleEvent(.coin)
        assertLog("unlock()", "thankyou()")
        
        try sut.fsm.handleEvent(.coin)
        assertLog("unlock()", "thankyou()", "thankyou()")
        
        try sut.fsm.handleEvent(.pass)
        assertLog("unlock()", "thankyou()", "thankyou()", "lock()")
        
        try sut.fsm.handleEvent(.pass)
        assertLog("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
}
