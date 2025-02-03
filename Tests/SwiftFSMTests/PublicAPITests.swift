import XCTest
import SwiftFSM
// Do not use @testable here //

final class PublicAPITests: XCTestCase {
    final class SUT: SyntaxBuilder, @unchecked Sendable {
        enum State { case locked, unlocked }
        enum Event { case coin, pass }
        
        let fsm = FSM<State, Event>(initialState: .locked)
        
        init() async throws {
            try await fsm.buildTable {
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
    
    func testPublicAPI() async throws {
        func assertLogged(_ a: String..., line: UInt = #line) {
            XCTAssertEqual(sut.log, a, line: line)
        }
        
        let sut = try await SUT()
        XCTAssert(sut.log.isEmpty)
        
        await sut.fsm.handleEvent(.coin)
        assertLogged("unlock()")
        
        await sut.fsm.handleEvent(.coin)
        assertLogged("unlock()", "thankyou()")
        
        await sut.fsm.handleEvent(.coin)
        assertLogged("unlock()", "thankyou()", "thankyou()")
        
        await sut.fsm.handleEvent(.pass)
        assertLogged("unlock()", "thankyou()", "thankyou()", "lock()")
        
        await sut.fsm.handleEvent(.pass)
        assertLogged("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
}
