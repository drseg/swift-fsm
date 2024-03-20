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
    
    var unlockCalled = false
    var lockCalled = false
    var alarmCalled = false
    var thankyouCalled = false
    
    func unlock() {
      unlockCalled = true
    }
    func alarm() { alarmCalled = true }
    func thankyou() { thankyouCalled = true }
    func lock() { lockCalled = true }
  }
  
  @MainActor
  func testPublicInterface() throws {
    let sut = try MyClass()
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
