# SwiftFSM

Inspired by [Uncle Bob's SMC][1] syntax, SwiftFSM is a pure Swift syntax for declaring and operating a Finite State Machine (FSM). Unlike Uncle Bob’s SMC, the FSM itself is declared inside your Swift code, rather than as a separate text file, and compiles and runs directly alongside all your other project code.

This guide is reasonably complete, but does presume some familiarity with FSMs and specifically the SMC syntax linked above.

### Requirements:

SwiftFSM is a Swift package, importable through the Swift Package Manager, and requires macOS 12.6 and/or iOS 15.6 or later, alongside Swift 5.6 or later.

### Example:

Borrowing from SMC, we have an example of a simple subway turnstile system. This turnstile currently has two possible states: `Locked`, and `Unlocked`, alongside two possible events: `Coin`, and `Pass`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - **Given** we are in the **Locked** state, **when** we get a **Coin** event, **then** we transition to the **Unlocked** state and **invoke** the **unlock** action.
> - **Given** we are in the **Locked** state, **when** we get a **Pass** event, **then** we stay in the **Locked** state and **invoke** the **alarm** action.
> - **Given** we are in the **Unlocked** state, **when** we get a **Coin** event, **then** we stay in the **Unlocked** state and **invoke** the **thankyou** action.
> - **GIven** we are in the **Unlocked** state, **when** we get a **Pass** event, **then** we transition to the **Locked** state and **invoke** the **lock** action.

Following Uncle Bob’s examples, we will build up our table bit by bit to demonstrate the different syntactic possibilities of SwiftFSM:

#### Stage 1 :

SMC Stage 1:

```
Initial: Locked
FSM: Turnstile
{
  Locked    {
    Coin    Unlocked    unlock
    Pass    Locked      alarm
  }
  Unlocked  {
    Coin    Unlocked    thankyou
    Pass    Locked      lock
  }
}
```

SwiftFSM Stage 2 (with additional code for context):

```swift
class MyClass: TransitionBuilder {
    let fsm = FSM<State, Event>(initialState: .locked)

    try! fsm.buildTable {
        define(.locked) {
            when(.coin) | then(.unlocked) | unlock
            when(.pass) | then(.locked)   | alarm
        }

        define(.unlocked) {
            when(.coin) | then(.unlocked) | thankyou
            when(.pass) | then(.locked)   | lock
        }
    }

    fsm.handleEvent(.coin)
}
```

Here we can see the four natural language sentences translated into a minimalistic syntax capable of expressing their essential logic.

Reading line by line:

```swift
class MyClass: TransitionBuilder {
```

The `TransitionBuilder` protocol provides the methods `define`, `when`, and `then` necessary to build the transition table. It has no requirements.

```swift
let fsm = FSM<State, Event>(initialState: .locked)
```

`FSM` is a generic class over `State` and `Event`. `State` and `Event` must be `Hashable`. Here we have used an `Enum`, specifying the initial state of the FSM as `.locked`.

```swift
try! fsm.buildTable {
```

`fsm.buildTable` is a throwing function that performs significant and detailed error handling on its input. Though the type system will prevent compilation of various illogical statements, there are some that can only be checked at runtime.

```swift
define(.locked) {
```

The `define` statement roughly corresponds to the ‘Given’ keyword in the natural language description of the FSM. It is expected however that you will only write one `define` per state. If you compare this to the equivalent SMC syntax, it allows for a deduplication, as the given state is only written once.

`define` takes two arguments - a `State` instance, and a Swift `@resultBuilder` block.

```swift
when(.coin) | then(.unlocked) | unlock
```

As we are inside a `define` block, we take the `.locked` state as a given. We can now list our transitions, with each line representing a single transition. In this case, `when` we receive a `.coin` event, we will `then` transition to the `.unlocked` state and call the `unlock` function. 

Here, `unlock` is a function, and could equally be declared as follows:

```swift
when(.coin) | then(.unlocked) | { unlock() //; otherFunction(); etc. }
```

The `|` (pipe) operator binds transitions together. It feeds the output of the left hand side into the input of the right hand side, as you might expect in a terminal.

Activating the FSM is as follows:

```swift
fsm.handleEvent(.coin)
```

The `FSM` instance will look up the appropriate transition for its current state, call the associated function, and transition to the associated next state. In this case, the `FSM` will call the `unlock` function and transition to the `unlocked` state. 

If no transition is found, it will do nothing.

#### Stage 2:

> Now let's add an Alarming state that must be reset by a repairman:

SMC:

```
Initial: Locked
FSM: Turnstile
{
  Locked    {
    Coin    Unlocked    unlock
    Pass    Alarming    alarmOn
    Reset   -           {alarmOff lock}
  }
  Unlocked  {
    Reset   Locked      {alarmOff lock}
    Coin    Unlocked    thankyou
    Pass    Locked      lock
  }
  Alarming {
    Coin    -          -
    Pass    -          -  
    Reset   Locked     {alarmOff lock}
  }
}
```

SwiftFSM:

```swift
try! fsm.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.pass) | then(.alarming) | alarmOn
        when(.reset)| then() 		  | { alarmOff(); lock() }
    }

    define(.unlocked) {
        when(.reset)| then(.locked)   | { alarmOff(); lock() }
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)   | lock
    }

    define(.alarming) {
        when(.coin)  | then()
        when(.pass)  | then()
        when(.reset) | then(.locked) | { alarmOff() ; lock() }
    }
}
```

The new SwiftFSM syntax elements here are:

`then()`, without any argument - this means ‘no change’, and will remain in the current state. It also shows optional actions statements. If nothing is stated, no actions will be performed.

#### Stage 3:

> Notice the duplication of the Reset transition. In all three states the Reset event does the same thing. It transitions to the Locked state and it invokes the lock and alarmOff actions. This duplication can be eliminated by using a Super State as follows:

SMC:

```
Initial: Locked
FSM: Turnstile
{
  // This is an abstract super state.
  (Resetable)  {
    Reset       Locked       {alarmOff lock}
  }
  Locked : Resetable    { 
    Coin    Unlocked    unlock
    Pass    Alarming    alarmOn
  }
  Unlocked : Resetable {
    Coin    Unlocked    thankyou
    Pass    Locked      lock
  }
  Alarming : Resetable { // inherits all it's transitions from Resetable.
  }
}
```

SwiftFSM:

```swift
try! fsm.buildTable {
    let resetable = SuperState {
        when(.reset) | then(.locked) | { alarmOff(); lock() }
    }

    define(.locked, superState: resetable) {
        when(.coin) | then(.unlocked) | unlock
        when(.pass) | then(.alarming) | alarmOn
    }

    define(.unlocked, superState: resetable) {
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)   | lock
    }

    define(.alarming, superState: resetable)
}
```

New for this stage is the `SuperState` struct. This takes a `@resultBuilder` block in exactly the same way that `define` does, however it does not take a starting state as an argument. The starting state is taken from the `define` statement in which it is used. Giving a `SuperState` instance to a `define` call as an argument will cause all of the transitions declared in to the `SuperState` to be added alongside the other transitions declared in the `define`. 

[1]:	https://github.com/unclebob/CC_SMC