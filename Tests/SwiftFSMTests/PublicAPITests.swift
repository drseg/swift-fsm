import XCTest
import SwiftFSM
// Do not use @testable here //

final class PublicAPITests: XCTestCase {
    @MainActor
    class SUT: SyntaxBuilder {
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
        
        func unlock() async { logAction() }
        func alarm() async { logAction() }
        func thankyou() async { logAction() }
        func lock() async { logAction() }
        
        var log = [String]()
        
        func logAction(_ f: String = #function) {
            log.append(f)
        }
    }
    
    func testPublicAPI() async throws {
        func assertLogged(_ a: String..., line: UInt = #line) async {
            let log = await sut.log
            XCTAssertEqual(log, a, line: line)
        }
        
        let sut = try await SUT()
        let log = await sut.log
        XCTAssert(log.isEmpty)
        
        await sut.fsm.handleEvent(.coin)
        await assertLogged("unlock()")
        
        await sut.fsm.handleEvent(.coin)
        await assertLogged("unlock()", "thankyou()")
        
        await sut.fsm.handleEvent(.coin)
        await assertLogged("unlock()", "thankyou()", "thankyou()")
        
        await sut.fsm.handleEvent(.pass)
        await assertLogged("unlock()", "thankyou()", "thankyou()", "lock()")
        
        await sut.fsm.handleEvent(.pass)
        await assertLogged("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
}
