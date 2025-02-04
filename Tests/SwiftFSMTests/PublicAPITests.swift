import XCTest
import SwiftFSM
// Do not use @testable here //

final class PublicAPITests: XCTestCase {
    @MainActor
    class SUT: SyntaxBuilder {
        enum State { case locked, unlocked }
        enum Event { case coin, pass }
        
        let turnstile: FSM<State, Event>
        
        init() async throws {
            turnstile = FSM<State, Event>(initialState: .locked)
            
            try turnstile.buildTable {
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
    
    @MainActor
    func testPublicAPI() async throws {
        func assertLogged(_ a: String..., line: UInt = #line) async {
            let log = sut.log
            XCTAssertEqual(log, a, line: line)
        }
        
        let sut = try await SUT()
        let log = sut.log
        XCTAssert(log.isEmpty)
        
        await sut.turnstile.handleEvent(.coin)
        await assertLogged("unlock()")
        
        await sut.turnstile.handleEvent(.coin)
        await assertLogged("unlock()", "thankyou()")
        
        await sut.turnstile.handleEvent(.coin)
        await assertLogged("unlock()", "thankyou()", "thankyou()")
        
        await sut.turnstile.handleEvent(.pass)
        await assertLogged("unlock()", "thankyou()", "thankyou()", "lock()")
        
        await sut.turnstile.handleEvent(.pass)
        await assertLogged("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
}
