import XCTest
import SwiftFSM
// Do not use @testable here //

final class PublicAPITests: XCTestCase {
    // These make little attempt to avoid duplication, as the point is to test the public API as-is, so polymorphism, additional protocols, etc. should be avoided
    
    class SUT: SyntaxBuilder {
        enum State { case locked, unlocked }
        enum Event { case coin, pass }
        
        let turnstile: FSM<State, Event>
        
        init() throws {
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
    
    func testPublicAPI() async throws {
        func assertLogged(_ a: String..., line: UInt = #line) {
            XCTAssertEqual(sut.log, a, line: line)
        }
        
        let sut = try SUT()
        XCTAssert(sut.log.isEmpty)
        
        await sut.turnstile.handleEvent(.coin)
        assertLogged("unlock()")
        
        await sut.turnstile.handleEvent(.coin)
        assertLogged("unlock()", "thankyou()")
        
        await sut.turnstile.handleEvent(.coin)
        assertLogged("unlock()", "thankyou()", "thankyou()")
        
        await sut.turnstile.handleEvent(.pass)
        assertLogged("unlock()", "thankyou()", "thankyou()", "lock()")
        
        await sut.turnstile.handleEvent(.pass)
        assertLogged("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
    
    @MainActor
    class MainActorSUT: SyntaxBuilder {
        enum State { case locked, unlocked }
        enum Event { case coin, pass }
        
        let turnstile: MainActorFSM<State, Event>
        
        init() throws {
            turnstile = MainActorFSM<State, Event>(initialState: .locked)
            
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
    func testMainActorPublicAPI() async throws {
        func assertLogged(_ a: String..., line: UInt = #line) {
            XCTAssertEqual(sut.log, a, line: line)
        }
        
        let sut = try MainActorSUT()
        XCTAssert(sut.log.isEmpty)
        
        await sut.turnstile.handleEvent(.coin)
        assertLogged("unlock()")
        
        await sut.turnstile.handleEvent(.coin)
        assertLogged("unlock()", "thankyou()")
        
        await sut.turnstile.handleEvent(.coin)
        assertLogged("unlock()", "thankyou()", "thankyou()")
        
        await sut.turnstile.handleEvent(.pass)
        assertLogged("unlock()", "thankyou()", "thankyou()", "lock()")
        
        await sut.turnstile.handleEvent(.pass)
        assertLogged("unlock()", "thankyou()", "thankyou()", "lock()", "alarm()")
    }
}
