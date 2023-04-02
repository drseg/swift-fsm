# SwiftFSM

Inspired by [Uncle Bob's SMC][1] syntax, SwiftFSM is a pure Swift syntax for declaring and operating a Finite State Machine (FSM). Unlike Uncle Bob’s SMC, the FSM itself is declared inside your Swift code, rather than as a separate text file, and compiles and runs directly alongside all your other project code.

This guide is reasonably complete, but does presume some familiarity with FSMs and specifically the SMC syntax linked above.

## Requirements:

SwiftFSM is a Swift package, importable through the Swift Package Manager, and requires macOS 12.6 and/or iOS 15.6 or later, alongside Swift 5.6 or later.

## Example:

Borrowing from SMC, we have an example of a simple subway turnstile system. This turnstile currently has two possible states: `Locked`, and `Unlocked`, alongside two possible events: `Coin`, and `Pass`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - **Given** we are in the **Locked** state, **when** we get a **Coin** event, **then** we transition to the **Unlocked** state and **invoke** the **unlock** action.
> - **Given** we are in the **Locked** state, **when** we get a **Pass** event, **then** we stay in the **Locked** state and **invoke** the **alarm** action.
> - **Given** we are in the **Unlocked** state, **when** we get a **Coin** event, **then** we stay in the **Unlocked** state and **invoke** the **thankyou** action.
> - **GIven** we are in the **Unlocked** state, **when** we get a **Pass** event, **then** we transition to the **Locked** state and **invoke** the **lock** action.

Following Uncle Bob’s examples, we will build up our table bit by bit to demonstrate the different syntactic possibilities of SwiftFSM:

### Basic Syntax:

SMC:

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

SwiftFSM (with additional code for context):

```swift
class MyClass: TransitionBuilder {
    enum State { case locked, unlocked }
    enum Event { case coin, pass }

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

```swift
class MyClass: TransitionBuilder {
```

The `TransitionBuilder` protocol provides the methods `define`, `when`, and `then` necessary to build the transition table. It has two associated types, `State` and `Event`, which must be `Hashable`.

```swift
let fsm = FSM<State, Event>(initialState: .locked)
```

`FSM` is generic  over `State` and `Event`.  As with `TransitionBuilder`, `State` and `Event` must be `Hashable`. Here we have used an `Enum`, specifying the initial state of the FSM as `.locked`.

```swift
try! fsm.buildTable {
```

`fsm.buildTable` is a throwing function - though the type system will prevent various illogical statements, there are some issues that can only be detected at runtime.

```swift
define(.locked) {
```

The `define` statement roughly corresponds to the ‘Given’ keyword in the natural language description of the FSM. It is expected however that you will only write one `define` per state.

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

```swift
fsm.handleEvent(.coin)
```

The `FSM` instance will look up the appropriate transition for its current state, call the associated function, and transition to the associated next state. In this case, the `FSM` will call the `unlock` function and transition to the `unlocked` state.  If no transition is found, it will do nothing.

### Optional Arguments:

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

`then()`with no argument means ‘no change’, and the FSM will remain in the current state.  The actions argument is also optional - if a transition performs no actions, it can be omitted.

### Super States:

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

`SuperState`  takes a `@resultBuilder` block like `define`, however it does not take a starting state. The starting state is taken from the `define` statement in which it is used. Pass a `SuperState` instance to a `define` call  will add the transitions declared in the `SuperState` to the other transitions declared in the `define`. 

If a `SuperState` instance is given, the `@resultBuilder` argument to `define` is optional.

### Entry and Exit Actions

> > In the previous example, the fact that the alarm is turned on every time the Alarming state is entered and is turned off every time the Alarming state is exited, is hidden within the logic of several different transitions. We can make it explicit by using entry actions and exit actions.

SMC:

```
Initial: Locked
FSM: Turnstile
{
  (Resetable) {
    Reset       Locked       -
  }
  Locked : Resetable <lock     {
    Coin    Unlocked    -
    Pass    Alarming    -
  }
  Unlocked : Resetable <unlock  {
    Coin    Unlocked    thankyou
    Pass    Locked      -
  }
  Alarming : Resetable <alarmOn >alarmOff   -    -    -
}
```

SwiftFSM:

```swift
try fsm.buildTable {
    let resetable = SuperState {
        when(.reset) | then(.locked)
    }

    define(.locked, superState: resetable, onEntry: [lock]) {
        when(.coin) | then(.unlocked)
        when(.pass) | then(.alarming)
    }

    define(.unlocked, superState: resetable, onEntry: [unlock]) {
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)
    }

    define(.alarming, superState: resetable, onEntry: [alarmOn], onExit: [alarmOff])
    }
```

`onEntry` and `onExit` are the final arguments to `define` and specify an array of entry and exit actions to be performed when entering or leaving the defined state.

### Syntax Variations

SwiftFSM allows you to alter the naming conventions in your syntax by using `typealiases`. Though `define`, `when`, and `then` are functions, there are matching structs with equivalent capitalised names contained in the `SwiftFSM.Syntax` namespace.

Examples include…

```swift
typealias State = Syntax.Define<State>
typealias Event = Syntax.When<Event>
typealias NextState = Syntax.Then<State>

try! fsm.buildTable {
    State(.locked) {
        Event(.coin) | NextState(.unlocked) | unlock
        Event(.pass) | NextState(.locked)   | alarm
    }

    State(.unlocked) {
        Event(.coin) | NextState(.unlocked) | thankyou
        Event(.pass) | NextState(.locked)   | lock
    }
}
```

…or for absolute minimalism…

```swift
typealias d = Syntax.Define<State>
typealias w = Syntax.When<Event>
typealias t = Syntax.Then<State>

try! fsm.buildTable {
    d(.locked) {
        w(.coin) | t(.unlocked) | unlock
        w(.pass) | t(.locked)   | alarm
    }

    d(.unlocked) {
        w(.coin) | t(.unlocked) | thankyou
        w(.pass) | t(.locked)   | lock
    }
}
```

It you wish to use this alternative syntax, it is strongly recommended that you *do not implement `TransitionBuilder`*. Use the function syntax provided by `TransitionBuilder`, *or* the struct syntax provided by the `Syntax` namespace. 

No harm will befall the FSM if you mix and match, but at the very least, from an autocomplete point of view, things will get messy. 

[1]:	https://github.com/unclebob/CC_SMC