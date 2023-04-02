# SwiftFSM

Inspired by [Uncle Bob's SMC][1] syntax, SwiftFSM is a pure Swift syntax for declaring and operating Finite State Machines (FSM). Unlike Uncle Bob’s SMC, the FSM itself is declared inside your Swift code, rather than as a separate text file, and compiles and runs directly alongside all your other project code.

### Requirements:

SwiftFSM is a Swift package, importable through the Swift Package Manager, and requires macOS 12.6 and/or iOS 15.6 or later, alongside Swift 5.6 or later.

### Example:

Borrowing from SMC, we have an example of a simple subway turnstile system. This turnstile has three possible states: `Locked`, `Unlocked`, and `Alarming`, alongside three possible events: `Coin`, `Pass`, and `Reset`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - **Given** we are in the **Locked** state, **when** we get a **Coin** event, **then** we transition to the **Unlocked** state and **invoke** the **unlock** action.
> - **Given** we are in the **Locked** state, **when** we get a **Pass** event, **then** we stay in the **Locked** state and **invoke** the **alarm** action.
> - **Given** we are in the **Unlocked** state, **when** we get a **Coin** event, **then** we stay in the **Unlocked** state and **invoke** the **thankyou** action.
> - **GIven** we are in the **Unlocked** state, **when** we get a **Pass** event, **then** we transition to the **Locked** state and **invoke** the **lock** action.

Following Uncle Bob’s examples, we will build up our table bit by bit to demonstrate the syntax required to produce a fully working FSM:

Uncle Bob:

```
Initial: Locked
FSM: Turnstile
{
  Locked    Coin    Unlocked    unlock
  Locked    Pass    Locked      alarm
  Unlocked  Coin    Unlocked    thankyou
  Unlocked  Pass    Locked      lock
}
```

SwiftFSM:

```swift
let fsm = FSM<State, Event>(initialState: .locked)

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
```



[1]:	https://github.com/unclebob/CC_SMC