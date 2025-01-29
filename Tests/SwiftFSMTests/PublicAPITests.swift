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
        
        var unlockCalled = false
        var lockCalled = false
        var alarmCalled = false
        var thankyouCalled = false
        
        func unlock() { unlockCalled = true }
        func alarm() { alarmCalled = true }
        func thankyou() { thankyouCalled = true }
        func lock() { lockCalled = true }
    }
    
    @MainActor
    func testPublicAPI() throws {
        let sut = try SUT()
        
        try sut.fsm.handleEvent(.coin)
        XCTAssertTrue(sut.unlockCalled)
        XCTAssertFalse(sut.thankyouCalled)
        
        try sut.fsm.handleEvent(.coin)
        XCTAssertTrue(sut.thankyouCalled)
        
        try sut.fsm.handleEvent(.coin)
        XCTAssertFalse(sut.lockCalled)
        
        try sut.fsm.handleEvent(.pass)
        XCTAssertTrue(sut.lockCalled)
        
        try sut.fsm.handleEvent(.pass)
        XCTAssertTrue(sut.alarmCalled)
    }
}
