# SwiftFSM

Inspired by [Uncle Bob's SMC][1] syntax, SwiftFSM is a pure Swift syntax for declaring and operating a Finite State Machine (FSM). Unlike Uncle Bob’s SMC, the FSM itself is declared inside your Swift code, rather than as a separate text file, and compiles and runs directly alongside all your other project code.

### Requirements:

SwiftFSM is a Swift package, importable through the Swift Package Manager, and requires macOS 12.6 and/or iOS 15.6 or later, alongside Swift 5.6 or later.

### Example:

Borrowing from SMC, we have an example of a simple subway turnstile system. This turnstile currently has two possible states: `Locked`, and `Unlocked`, alongside two possible events: `Coin`, and `Pass`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - **Given** we are in the **Locked** state, **when** we get a **Coin** event, **then** we transition to the **Unlocked** state and **invoke** the **unlock** action.
> - **Given** we are in the **Locked** state, **when** we get a **Pass** event, **then** we stay in the **Locked** state and **invoke** the **alarm** action.
> - **Given** we are in the **Unlocked** state, **when** we get a **Coin** event, **then** we stay in the **Unlocked** state and **invoke** the **thankyou** action.
> - **GIven** we are in the **Unlocked** state, **when** we get a **Pass** event, **then** we transition to the **Locked** state and **invoke** the **lock** action.

Following Uncle Bob’s examples, we will build up our table bit by bit to demonstrate the different syntactic possibilities when building up our FSM:

#### Stage 1:

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

SwiftFSM equivalent (with additional code for context):

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

The `TransitionBuilder` protocol provides the methods `define`, `when`, and `then` necessary to build the transition table and feed it to the FSM. It does not require the conformer to implement anything, and does not pose any restrictions on the identity of the conformer.

```swift
let fsm = FSM<State, Event>(initialState: .locked)
```

`FSM` is a generic class over `State` and `Event`. `State` and `Event` must be `Hashable` (and because their hashing must be value based, they cannot be or contain `NSObject` types or instances). Otherwise, there are no specific requirements, though for Swift it is likely you will wish to use an `Enum` as in the example above. Here we have specified the initial state of the FSM as `.locked`.

```swift
try! fsm.buildTable {
```

`fsm.buildTable` is a throwing function that performs significant and detailed error handling on its input. For this reason, it is unlikely you will want to use a bang here - it is stated this way simply for simplicity of illustration. Though the type system will prevent the compilation of various illogical or meaningless statements, there are some that can only be checked at runtime.

```swift
define(.locked) {
```

The `define` statement is the cornerstone of the syntax. It corresponds to the ‘Given’ keyword in the natural language description of the FSM, however is more comprehensive, as it is expected that you will only write one `define` per state. If you compare this to the equivalent SMC syntax, it allows for a degree of deduplication, as the given state only has to be written once.

`define` takes two arguments - a `State` instance, and a Swift `@resultBuilder` block. Though the compiler will allow empty blocks, they are not allowed by FSM and will throw an error.

```swift
when(.coin) | then(.unlocked) | unlock
```

This is the meat of the table, and declares a full transition. As we are inside a `define` block, we take the `.locked` state as a given. We can now list our transitions, with each line representing a single transition. In this case, `when` we receive a `.coin` event, we will `then` transition to the `.unlocked` state and call the `unlock` function. 

Here, `unlock` is simply a function, and could equally be declared as follows, which can be useful if you wish to call multiple functions:

```swift
when(.coin) | then(.unlocked) | { unlock() //; otherFunction(); etc. }
```

The `|` (pipe) operator is the glue that binds transitions together. It acts more as a pipe than a bitwise OR, and feeds the output of the left hand side into the input of the right hand side, as you might expect in a terminal. The operator has the same precedence as `+`.

Activating the FSM is a single function call:

```swift
fsm.handleEvent(.coin)
```

The `FSM` instance will look up the appropriate transition for its current state, call the associated function, and transition to the associated next state. In this case, the `FSM` will call the `unlock` function and transition to the `unlocked` state.

[1]:	https://github.com/unclebob/CC_SMC