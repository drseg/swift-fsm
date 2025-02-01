# Swift FSM
[![codecov][image-1]][1] ![Testspace tests][image-2] ![GitHub Workflow Status][image-3] ![GitHub][image-4]

**Friendly Finite State Machine Syntax for Swift on macOS, iOS, tvOS and watchOS**

Inspired by [Uncle Bob's SMC][2] syntax, Swift FSM is a pure Swift DSL for declaring and operating a Finite State Machine (FSM).

This guide presumes some familiarity with FSMs and specifically the SMC syntax linked above. Swift FSM makes liberal use of [`@resultBuilder`][3] blocks,  [operator overloads][4],  [`callAsFunction()`][5], and [trailing closures][6], all in combination with one another - familiarity with these concepts will also be helpful.

## Requirements

Swift FSM is a Swift Package for all Apple platforms, available through the Swift Package Manager, and requires Swift 6 or later. It is tested against strict concurrency rules and should be fully compliant.

It has one dependency - Apple’s [Algorithms][7].

## Basic Syntax

Borrowing from SMC, we will use the example of a subway turnstile system. This turnstile has two possible states: `Locked`, and `Unlocked`, and two possible events: `Coin`, and `Pass`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - *Given* we are in the *Locked* state, *when* we get a *Coin* event, *then* we transition to the *Unlocked* state and *invoke* the *unlock* action.
> - *Given* we are in the *Locked* state, *when* we get a *Pass* event, *then* we stay in the *Locked* state and *invoke* the *alarm* action.
> - *Given* we are in the *Unlocked* state, *when* we get a *Coin* event, *then* we stay in the *Unlocked* state and *invoke* the *thankyou* action.
> - *GIven* we are in the *Unlocked* state, *when* we get a *Pass* event, *then* we transition to the *Locked* state and *invoke* the *lock* action.

Following Uncle Bob’s examples, we will build up our table bit by bit to demonstrate the different syntactic possibilities of Swift FSM and how they compare to SMC:

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

Swift FSM (with additional code for context):

```swift
import SwiftFSM

class MyClass: SyntaxBuilder {
    enum State { case locked, unlocked }
    enum Event { case coin, pass }

    let fsm = FSM<State, Event>(initialState: .locked)

    func myMethod() throws {
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

        try fsm.handleEvent(.coin)
    }
}
```

> ```swift
> class MyClass: SyntaxBuilder {
> ```

The `SyntaxBuilder` protocol provides the methods `define`, `when`, and `then` necessary to build the transition table. It has two associated types, `State` and `Event`, which must be `Hashable & Sendable`. The protocol itself is `@MainActor` isolated, requiring your implementation to be similarly isolated.

> ```swift
> let fsm = FSM<State, Event>(initialState: .locked)
> ```

`FSM` is generic  over `State` and `Event`.  As with `SyntaxBuilder`, `State` and `Event` must be `Hashable & Sendable`. Here we have used an `Enum`, specifying the initial state of the FSM as `.locked`.

> ```swift
> try fsm.buildTable {
> ```

`fsm.buildTable` is a throwing function - though the type system will prevent various illogical statements, there are some issues that can only be detected at runtime.

> ```swift
> define(.locked) {
> ```

The `define` statement roughly corresponds to the ‘Given’ keyword in the natural language description of the FSM. It is expected however that you will only write one `define` per state.

`define` takes two arguments - a `State` instance, and a Swift `@resultBuilder` block.

> ```swift
> when(.coin) | then(.unlocked) | unlock
> ```

As we are inside a `define` block, we take the `.locked` state as a given. We can now list our transitions, with each line representing a single transition. In this case, `when` we receive a `.coin` event, we will `then` transition to the `.unlocked` state and call `unlock`. 

`unlock` is a function, also declarable as follows:

> ```swift
> when(.coin) | then(.unlocked) | { unlock() //; otherFunction(); etc. }
> ```

(see [Arrays of Actions][10] for other syntax variants)

The `|` (pipe) operator binds transitions together. It feeds the output of the left hand side into the input of the right hand side, as you might expect in a terminal.

> ```swift
> try fsm.handleEvent(.coin)
> ```

The `FSM` instance will look up the appropriate transition for its current state, call the associated function, and transition to the associated next state. In this case, the `FSM` will call the `unlock` function and transition to the `unlocked` state.  If no transition is found, it will do nothing, and if compiled for debugging, will print a warning message.

#### Actions and Concurrency

Currently, in order to work reasonably in a SwiftUI and Swift Concurrency world, the FSM runs its critical loops on the Main Actor, and expects that the actions you pass it will do so as well. Internally, the method `handleEvent` and all actions are therefore annotated `@MainActor`.

There are two versions of `handleEvent`, the first as shown above and in all the examples, and the second named `handleEventAsync` which must be called with `await`. 

The four function signatures for actions that are accepted are as follows:

```swift
@MainActor () -> Void
@MainActor () async -> Void
@MainActor (Event) -> Void
@MainActor (Event) async -> Void
```

These are handled interchangeably without any additional syntax. The tradeoff is that you must choose the appropriate `handleEvent` function to call when using the FSM. The synchronous `handleEvent` function must be called with `try`, because it will throw if it is asked to call an async action. Though the asynchronous `handleEventAsync` function must be called with `await`, it does not throw any errors as it is a valid context from which to call both synchronous and asynchronous actions.

Note also that there are action signatures that take an event as an argument. This can be useful in situations where you wish to pass an associated value along with an event enum that can then be received by your callback function (see [Using Events to Pass Values][11] for more details on how to implement this) .

##### Arrays of Actions

If you wish to pass an array of actions anywhere where such arrays are accepted, you will need to use a special `&` operator in order to enable mixing and matching of the four different action signatures:

```swift
when(.coin) | then(.unlocked) | first & secondAsync & thirdWithEvent ...
```

This is equivalent to the more verbose (but equally valid):

```swift
when(.coin) | then(.unlocked) | { event in first(); await secondAsync(); thirdWithEvent(event) ... }
```

### Optional Arguments

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

Swift FSM:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.coin)  | then(.unlocked) | unlock
        when(.pass)  | then(.alarming) | alarmOn
        when(.reset) | then()          | alarmOff & lock
    }

    define(.unlocked) {
        when(.reset) | then(.locked)   | alarmOff & lock
        when(.coin)  | then(.unlocked) | thankyou
        when(.pass)  | then(.locked)   | lock
    }

    define(.alarming) {
        when(.coin)  | then()
        when(.pass)  | then()
        when(.reset) | then(.locked)   | alarmOff & lock
    }
}
```

`then()` with no argument means ‘no change’, and the FSM will remain in the current state.  The actions pipe is also optional - if a transition performs no actions, it can be omitted.

### Super States

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

Swift FSM:

```swift
try fsm.buildTable {
    let resetable = SuperState {
        when(.reset) | then(.locked)  | alarmOff & lock
    }

    define(.locked, adopts: resetable) {
        when(.coin) | then(.unlocked) | unlock
        when(.pass) | then(.alarming) | alarmOn
    }

    define(.unlocked, adopts: resetable) {
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)   | lock
    }

    define(.alarming, adopts: resetable)
}
```

`SuperState` takes the same `@resultBuilder` as `define`, however it does not take a starting state. The starting state is taken from the `define` statement to which it is passed. Passing `SuperState` instances to a `define` call will add the transitions declared in each of the `SuperState` instances before the other transitions declared in the `define`. 

If a `SuperState` instance is passed to `define`, the `@resultBuilder` argument is optional.

`SuperState` instances themselves can adopt other `SuperState` instances, and will combine them together in the same way as `define`:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | unlock  }
let s2 = SuperState { when(.pass) | then(.alarming) | alarmOn }

let s3 = SuperState(adopts: s1, s2)

// s3 is equivalent to:

let s4 = SuperState {
    when(.coin) | then(.unlocked) | unlock
    when(.pass) | then(.alarming) | alarmOn
}
```

#### Overriding SuperStates

By default, transitions declared in a `SuperState` cannot be overridden by their adopters. The following code is therefore assumed to be accidental and throws:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | unlock  }

let s2 = SuperState(adopts: s1) { 
    when(.coin) | then(.locked) | beGrumpy // 💥 error: clashing transitions
}

define(.locked, adopts: s1) {
    when(.coin) | then(.locked) | beGrumpy // 💥 error: clashing transitions
}
```

If you wish to override a `SuperState` transition, you must make this explicit using the `overriding { }` block:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | unlock  }

let s2 = SuperState(adopts: s1) {
    overriding { 
        when(.coin) | then(.locked) | beGrumpy // ✅ overrides inherited transition
    }
}

define(.locked, adopts: s1) {
    overriding { 
        when(.coin) | then(.locked) | beGrumpy // ✅ overrides inherited transition
    }
}
```

The `overriding` block indicates to Swift FSM that any transitions contained within it override any inherited transitions with the same initial states and events. 

As multiple inheritance is allowed, overrides replace all matching transitions:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | doSomething     }
let s2 = SuperState { when(.coin) | then(.unlocked) | doSomethingElse }

define(.locked, adopts: s1, s2) {
    overriding { 
        when(.coin) | then(.locked) | doYetAnotherThing // ✅ overrides both inherited transitions
    }
}
```

Without the `overriding`, this multiple inheritance would otherwise create duplicate transitions:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | doSomething     }
let s2 = SuperState { when(.coin) | then(.unlocked) | doSomethingElse }

define(.locked, adopts: s1, s2) // 💥 error: duplicate transitions
```

If `overriding` is used where there is nothing to override, the FSM will throw:

```swift
define(.locked) {
    overriding { 
        when(.coin) | then(.locked) | beGrumpy // 💥 error: nothing to override
    }
}
```

Writing `overriding` in the parent rather than the child will throw:

```swift
let s1 = SuperState {
    overriding { 
        when(.coin) | then(.locked) | beGrumpy
    }
}

let s2 = SuperState(adopts: s1) { when(.coin) | then(.unlocked) | unlock }

// 💥 error: overrides are out of order
```

Attempting to override within the same `SuperState { }` or `define { }` will also throw:

```swift
define(.locked) {
    when(.coin) | then(.locked) | doSomething
    overriding { 
        when(.coin) | then(.locked) | doSomethingElse
    }
}

// 💥 error: duplicate transitions
```

In this scope, the word override has no meaning and therefore is ignored by the error handler. What remains is therefore two duplicate transitions, resulting in an error.

#### Override Chains

Overrides in Swift FSM follow the usual rules of inheritance. In a chain of overrides, it is the final transition in that chain that takes precedence:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | a1  }
let s2 = SuperState(adopts: s1) { overriding { when(.coin) | then(.unlocked) | a2 } }
let s3 = SuperState(adopts: s2) { overriding { when(.coin) | then(.unlocked) | a3 } }
let s4 = SuperState(adopts: s3) { overriding { when(.coin) | then(.unlocked) | a4 } }

define(.locked, adopts: s4) {
    overriding { when(.coin) | then(.unlocked) | a5 } // ✅ overrides all others
}

fsm.handleEvent(.coin) // 'a5' is called
```

### Entry and Exit Actions

> In the previous example, the fact that the alarm is turned on every time the Alarming state is entered and is turned off every time the Alarming state is exited, is hidden within the logic of several different transitions. We can make it explicit by using entry actions and exit actions.

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

Swift FSM:

```swift
try fsm.buildTable {
    let resetable = SuperState {
        when(.reset) | then(.locked)
    }

    define(.locked, adopts: resetable, onEntry: lock*) {
        when(.coin) | then(.unlocked)
        when(.pass) | then(.alarming)
    }

    define(.unlocked, adopts: resetable, onEntry: unlock*) {
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)
    }

    define(.alarming, adopts: resetable, onEntry: alarmOn*, onExit: alarmOff*)
}
```

`onEntry` and `onExit` are the final arguments to `define` and specify an array of entry and exit actions to be performed when entering or leaving the defined state. Note that these require array syntax rather than varargs, as a work around for limitations in Swift’s matching algorithm for functions that take multiple closure arguments. 

As the array is heterogeneous (it can include any of the four function types accepted by SwiftFSM as valid actions), a special postfix operator `*` is provided to convert a single one of these into an array of `AnyAction`. 

```swift
let _ = unlock* // preferred syntax, same as...
let _ = Array(unlock) // same as...
let _ = [AnyAction(unlock)]

let _ = unlock & thankyou // preferred syntax, same as...
let _ = AnyAction(unlock) & thankyou // same as...
let _ = AnyAction(unlock) & AnyAction(thankyou) // same as...
let _ = [AnyAction(unlock), AnyAction(thankyou)]
```

`SuperState` instances can also accept entry and exit actions:

```swift
let resetable = SuperState(onEntry: lock*) {
    when(.reset) | then(.locked)
}

define(.locked, adopts: resetable) {
    when(.coin) | then(.unlocked)
    when(.pass) | then(.alarming)
}

// equivalent to:

define(.locked, onEntry: lock*) {
    when(.reset) | then(.locked)
    when(.coin)  | then(.unlocked)
    when(.pass)  | then(.alarming)
}
```

`SuperState` instances also inherit entry and exit actions from their superstates:

```swift
let s1 = SuperState(onEntry: unlock*)  { when(.coin) | then(.unlocked) }
let s2 = SuperState(onEntry: alarmOn*) { when(.pass) | then(.alarming) }

let s3 = SuperState(adopts: s1, s2)

// s3 is equivalent to:

let s4 = SuperState(onEntry: [unlock, alarmOn]) { 
    when(.coin) | then(.unlocked)
    when(.pass) | then(.alarming)
}
```

#### Configuring Entry and Exit Actions Behaviour

In SMC, entry and exit actions are invoked even if the state does not change. In the example above, the unlock entry action would be called on all transitions into the `Unlocked` state, even if the FSM is already in the `Unlocked` state. 

In contrast, **Swift FSM’s default behaviour is to invoke entry and exit actions only if there is a state change**. In the example above, this means that, in the `.unlocked` state, after a `.coin` event, `unlock` will *not* be called.

This policy is configurable, by passing `.executeAlways` as the second argument to `FSM.init`:

```swift
FSM<State, Event>(initialState: .locked, actionsPolicy: .executeAlways)
```

This setting replicates SMC entry/exit action behaviour. The default is `.executeOnChangeOnly` and is not a required argument.

### Syntax Order

All statements must be made in the form `define { when | then | actions }`. See [Expanded Syntax][12] below for exceptions to this rule.

### Syntactic Sugar

 `when` statements accept vararg `Event` instances for convenience.

```swift
define(.locked) {
    when(.coin, or: .pass, ...) | then(.unlocked) | unlock
}

// equivalent to:

define(.locked) {
    when(.coin) | then(.unlocked) | unlock
    when(.pass) | then(.unlocked) | unlock
    ...
}
```

### Passing Values in Events

Actions can receive the event that resulted in them being called, which can be useful if that event includes a value you may wish to pass on. SwiftFSM requires a special struct `FSMValue<T>` and protocol `EventWithValues` that work together to enable you to do this.

```swift
enum Event: EventWithValues {
    case .coin(FSMValue<Int>), ...

    var coinValue: Int? {
        guard case .coin(let amount) = event else { return nil }
        return amount.wrappedValue
    }
}

func main() throws {
    try fsm.buildTable(initialState: .locked) {
        define(.locked) {
            when(.coin(.any)) | then(.verifyingPayment) | verifyPayment
            // here we use .any to match any value
        }
    }

    try fsm.handleEvent(.coin(50))
    // here we pass a specific value that will be matched by .any
}

func verifyPayment(_ event: Event) {
    // here we receive the actual value passed to handleEvent: .coin(50)
    if let amount = event.coinValue {
        if amount >= requiredAmount {
            letThemThrough()
        } else {
            insufficientPayment(shortfall: requiredAmount - amount)
        }
    }
}
```

 `when(.coin(.any))` works polymorphically. We wish to write a single transition row that will match against any value inside `.coin(someValue)` and pass that value on to the `verifyPayment` function. Without the combination of `EventWithValues` and `FSMValue<T>`, the table would have to be written as follows:

```swift
try fsm.buildTable(initialState: .locked) {
    define(.locked) {
        when(.coin(1)) | then(.verifyingPayment) | verifyPayment
        when(.coin(2)) | then(.verifyingPayment) | verifyPayment
        when(.coin(3)) | then(.verifyingPayment) | verifyPayment
        when(.coin(4)) | then(.verifyingPayment) | verifyPayment
        ... // and so on for all relevant values
    }
}
```

By using  `.any`, the transition to `.verifyingPayment` will be activated when a `.coin` event is received, no matter what the wrapped value is. That wrapped value is then passed into the `verifyPayment` function where it can be examined. `FSMValue` provides a convenience `var wrappedValue: T?`, which returns an optional value (potentially nil if it is called on a `.any` instance or if `T` is optional and nil).

#### Literal Expression Implementations

FSMValue conforms to `ExpressibleByIntegerLiteral`, `ExpressibleByFloatLiteral`, `ExpressibleByArrayLiteral`, `ExpressibleByDictionaryLiteral`, `ExpressionByNilLiteral`, and `ExpressionByStringLiteral` forwarding to the wrapped type where relevant. It also forwards conformances to `Equatable`, `Comparable`, and `AdditiveArithmetic` where relevant, as well as `RandomAccessCollection` and its parent protocols for Arrays, and subscript access for Dictionaries. Finally, it forwards `CustomStringConvertible`, which also covers most uses of `ExpressibleByStringInterpolation`.

A few examples:

```swift
let s: FSMValue<String> = "1" // equivalent to .some("1")
let i: FSMValue<Int> = 1 // equivalent to .some(1)
let ai: FSMValue<[Int]> = [1] // equivalent to .some([1])

let _ = s + "1" // "11"
let _ = i + 1 // 2
let _ = ai[0] // 1
let _ = ai[0] == i // true
let _ = ai[0] > i // false
let _ = "\(i)\(s)" // "11"
```

**Warning**: where forward operations are available on the wrapped type, be aware that this will crash if you attempt to access a value on a `.any` instance (as there is no instance of the wrapped type). `.any` should only appear inside a define statement - there are no circumstances in which it would be useful or meaningful to pass such an event with `FSMValue.any` to `handleEvent`.

Equally, you should always unwrap `FSMValue<T>` instances before continuing - indeed, all convenience methods that return a value return an instance of `T` and *not* of `FSMValue<T>`. Comparing or hashing `FSMValue` instances is not recommended - they are specialised DTOs used by the FSM and should not escape.

### Limitations of `@resultBuilder` Implementation

The `@resultBuilder` blocks in SwiftFSM do not support control flow logic. Though is it possible to enable such logic, it would be misleading:

```swift
define(.locked) {
    if something { // ⛔️ does not compile
        when(.pass) | then(.unlocked) | unlock
    } else {
        when(.pass) | then(.alarming) | alarmOn
    }
    ...
}
```

If the `if/else` block were evaluated by the FSM at transition time, this would be a useful addition. However what we are doing inside these blocks is *compiling* our state transition table. The use of `if` and `else` in this manner is more akin to the conditional compilation statements `#if/#else` - based on a value defined at compile time, only one transition or the other will be added to the table.

If you do have a use for this kind of conditional compilation, please open an issue. See [Expanded Syntax][13] for alternative ways to evaluate conditional statements at transition time rather than compile time.

### Runtime Errors

**Warning** - most Swift FSM function calls and initialisers take additional parameters `file: String = #file`  and `line: Int = #line`. This is similar to `XCTest` assertions, and allows Swift FSM to produce errors that pinpoint the location of problematic statement/s.

As these cannot be hidden, please note that there are unlikely to be any circumstances in which it would be useful or necessary to override these default arguments with alternate values.

#### Empty Blocks

All blocks must contain at least one transition, otherwise an error will be thrown:

```swift
try fsm.buildTable { } //💥 error: empty table
try fsm.buildTable {
    define(.locked) { } // 💥 error: empty block
}
```

#### Duplicate Transitions

Transitions are duplicates if they share the same start state, event, and next state:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.coin) | then(.unlocked) | lock
    }
}

// 💥 error: duplicate transitions
```

#### Logical Clashes

A logical clash occurs when transitions share the same start state and event, but their next states differ:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.coin) | then(.locked)   | lock
    }
}

// 💥 error: logical clash
```

Though the two transitions are distinct from one another, logically they cannot co-exist - the `.coin` event must lead either to the `.unlocked` state or to the `.locked` state. It cannot lead to both.

#### FSMValue - incorrect use of .any

Because `.any` matches all cases, the following would throw an error:

```swift
try fsm.buildTable(initialState: .locked) {
    define(.locked) {
        when(.coin(.any)) | then(.verifyingPayment) | verifyPayment
        when(.coin(50)    | then(.unlocked)         | pass
    }
} 

//💥 error: logical clash
```

The `.any` case already includes `.some(50)` and this specific case is therefore referenced ambiguously. It would however be possible to write the following:

```swift
try fsm.buildTable(initialState: .locked) {
    define(.locked) {
        when(.coin(20) | then(.verifyingPayment) | verifyPayment
        when(.coin(50) | then(.unlocked)         | pass
    }
} 

// ✅ transitions are logically distinct
```

#### Duplicate `buildTable` Calls

Additional calls to `fsm.buildTable { }` will throw a `TableAlreadyBuiltError`.

### Performance

Each call to `handleEvent()` requires a single operation to find the correct transition in the table. Though O(1) is ideal, this table-based system still has 2-3x the basic overhead of a nested switch case statement.

## Expanded Syntax

Whilst Swift FSM matches most of the syntax of SMC, it also introduces some new possibilities of its own. None of this additional syntax is required, and is provided purely for convenience.

### Example

Let’s imagine an extension to our turnstile rules: under some circumstances, we want to enforce the ‘everyone pays’ rule by entering the alarming state if a `.pass` is detected when still in the `.locked` state, yet in others, perhaps at rush hour, we want to be more permissive in order to avoid disruption to other passengers.

We could implement a time of day check somewhere else in the system, perhaps inside the implementation of the `alarmOn` function to decide what the appropriate behaviour should be:

```swift
try fsm.buildTable {
    ...
    define(.locked) {
        when(.pass) | then(.alarming) | handleAlarm
    }
    ...
}

// some other file...

enum Enforcement: Predicate { case weak, strong }

let enforcement = Enforcement.weak

func handleAlarm() {
    switch enforcement {
    case .weak: smile()
    case .strong: defconOne()
    }
}
```

But we now have some aspects of our state transition logic declared inside the transition table, and other aspects declared elsewhere. 

Furthermore, we must transition to the `.alarming` state, regardless of the `Enforcement` policy. But what if different policies called for different transitions altogether?

An alternative might be to introduce extra events to differentiate between the new policies:

```swift
try fsm.buildTable {
    ...
    define(.locked) {
        when(.passWithEnforcement)    | then(.alarming) | defconOne
        when(.passWithoutEnforcement) | then(.locked)   | smile
    }
    ...
}
```

This allows us both to call different functions, and to transition to different states, depending on the enforcement policy, all whilst keeping all of our logic inside the transition table.

In order to make this change however, every transition that originally responded to the `.pass` event will need to be rewritten twice, once for each of the two new versions of this event, *even if they are identical in both cases*. In no time at all, the state transition table is going to become unmanageably long, and littered with duplication. 

**The Swift FSM Solution**

```swift
import SwiftFSM

class MyClass: ExpandedSyntaxBuilder {
    enum State { case locked, unlocked }
    enum Event { case coin, pass }
    enum Enforcement: Predicate { case weak, strong }

    let fsm = FSM<State, Event>(initialState: .locked)

    func myMethod() throws {
        try fsm.buildTable {
            ...
            define(.locked) {
                matching(Enforcement.weak)   | when(.pass) | then(.locked)   | smile
                matching(Enforcement.strong) | when(.pass) | then(.alarming) | defconOne
                
                when(.coin) | then(.unlocked)
            }
            ...
       }
        
       fsm.handleEvent(.pass, predicates: Enforcement.weak)
    }
}
```

Here we have introduced a new keyword `matching`, and two new protocols, `ExpandedSyntaxBuilder` and `Predicate`. 

```swift
define(.locked) {
    matching(Enforcement.weak)   | when(.pass) | then(.locked)   | smile
    matching(Enforcement.strong) | when(.pass) | then(.alarming) | defconOne
                
    when(.coin) | then(.unlocked) | unlock
}
```

Given that we are in the `.locked` state:
- If `Enforcement` is `.weak`, when we get a `.pass`, transition to `.locked` and `smile`
- If `Enforcement` is `.strong`, when we get a `.pass`, transition to `.alarming` and `defconOne`
- *Regardless* of `Enforcement`, when we get a `.coin`, transition to `.unlocked` and `unlock`

In this system, only those statements that depend upon the `Enforcement` policy need know it has been added, and all other existing statements that do not depend upon it continue to work as they always did.

### ExpandedSyntaxBuilder and Predicate

`ExpandedSyntaxBuilder` implements `SyntaxBuilder`, providing all the SMC-equivalent syntax, alongside the new `matching` statements for working with predicates.  

`Predicate` requires the conformer to be `Hashable, Sendable` and `CaseIterable`. It is possible to use any type you wish, as long as your conformance to `Hashable` and `CaseIterable` makes logical sense. In practice, this is likely to limit `Predicates` to `Enums` without associated types, as these can be automatically conformed to `CaseIterable`.

### Implicit Matching Statements

```swift
when(.coin) | then(.unlocked)
```

In the above, no `Predicate` is specified, and its full meaning must therefore be inferred from context. The scope for contextual inference is the sum of the builder blocks for all `SuperState` and `define` calls inside `fsm.buildTable { }`.  

In our example, the type `Enforcement` appears in a `matching` statement elsewhere in the table, and Swift FSM will therefore infer the absent `matching` statement as follows:

```swift
when(.coin) | then(.unlocked)

// is inferred to mean:

matching(Enforcement.weak)   | when(.coin) | then(.unlocked)
matching(Enforcement.strong) | when(.coin) | then(.unlocked)
```

Transitions in Swift FSM are are therefore `Predicate` agnostic by default, matching any given `Predicate` unless otherwise specified. In this way, `matching` is an optional modifier that *constrains* the transition to one or more specific `Predicate` cases.

### Multiple Predicates

There is no limit on the number of `Predicate` types that can be used in one table (see [Predicate Performance][15] for practical limitations). The following (contrived and rather silly) expansion of the original `Predicate` example remains valid:

```swift
enum Enforcement: Predicate { case weak, strong }
enum Reward: Predicate { case positive, negative }

try fsm.buildTable {
    ...
    define(.locked) {
        matching(Enforcement.weak)   | when(.pass) | then(.locked)   | lock
        matching(Enforcement.strong) | when(.pass) | then(.alarming) | alarmOn
                
        when(.coin) | then(.unlocked) | unlock
    }

    define(.unlocked) {
        matching(Reward.positive) | when(.coin) | then(.unlocked) | thankyou
        matching(Reward.negative) | when(.coin) | then(.unlocked) | idiot

        when(.pass) | then(.locked) | lock
    }
    ...
}

fsm.handleEvent(.pass, predicates: Enforcement.weak, Reward.positive)
```

The same inference rules also apply:

```swift
when(.coin) | then(.unlocked)

// types Enforcement and Reward appear elsewhere in context
// when(.coin) | then(.unlocked) is now equivalent to:

matching(Enforcement.weak,   and: Reward.positive) | when(.coin) | then(.unlocked)
matching(Enforcement.strong, and: Reward.positive) | when(.coin) | then(.unlocked)
matching(Enforcement.weak,   and: Reward.negative) | when(.coin) | then(.unlocked)
matching(Enforcement.strong, and: Reward.negative) | when(.coin) | then(.unlocked)
```

#### Compound Matching Statements

As seen in the above example, multiple predicates can be combined in a single `matching` statement, by using the `and: Predicate...` and `or: Predicate...` varargs arguments.

```swift
enum A: Predicate { case x, y, z }
enum B: Predicate { case x, y, z }
enum C: Predicate { case x, y, z }

matching(A.x, or: A.y)... // if A.x OR A.y
matching(A.x, or: A.y, A.z)... // if A.x OR A.y OR A.z

matching(A.x, and: B.x)... // if A.x AND B.x
matching(A.x, and: B.x, C.x)... // if A.x AND B.x AND C.x

matching(A.x, or: A.y, A.z, and: B.x, C.x)... // if (A.x OR A.y OR A.z) AND B.x AND C.x

matching(A.x, or: B.x)...  // ⛔️ does not compile: OR types must be the same
matching(A.x, and: A.y)... // 💥 error: cannot match A.x AND A.y simultaneously

fsm.handleEvent(.coin, predicates: A.x, B.x, C.x)
```

In Swift FSM, `matching(and:)` means that we expect both predicates to be present at the same time, whereas `mathing(or:)` means that we expect any and only one of them to be present.

Swift FSM expects exactly one instance of each `Predicate` type present in the table to be passed to each call to `handleEvent`, as in the example above, where `fsm.handleEvent(.coin, predicates: A.x, B.x, C.x)` contains a single instance of types `A`, `B` and `C`. Accordingly, `A.x AND A.y` should never occur - only one can be present. Therefore, predicates passed to `matching(and:)` must all be of a different type.  This cannot be checked at compile time, and therefore throws at runtime if violated.

In contrast, `matching(or:)` specifies multiple possibilities for a single `Predicate`. Predicates joined by `or` must therefore all be of the same type, and attempting to pass different `Predicate` types to `matching(or:)` will not compile (see [Implicit Clashes][16] for more information on this limitation).

**Warning** - nested `matching` statements are combined by AND-ing them together, which makes it possible inadvertently to create a conflict.

```swift
define(.locked) {
    matching(A.x) {
        matching(A.y) {
            // 💥 error: cannot match A.x AND A.y simultaneously 
        }
    }
}
```

 `matching(or:)` statements are also combined using AND: 

```swift
define(.locked) {
    matching(A.x, or: A.y) {
        matching(A.z) {
            // 💥 error: cannot match A.x AND A.z simultaneously
            // 💥 error: cannot match A.y AND A.z simultaneously  
        }
    }
}
```

Valid nested `matching(or:)` statements are combined as follows:

```swift
define(.locked) {
    matching(A.x, or: A.y) {
        matching(B.x, or: B.y) {
            // ✅ logically matches (A.x OR A.y) AND (B.x OR B.y)

            // internally translates to:

            // 1. matching(A.x, and: B.x)
            // 2. matching(A.x, and: B.y)
            // 3. matching(A.y, and: B.x)
            // 4. matching(A.y, and: B.y)
        }
    }
}
```

### Implicit Clashes

#### Between-Predicates Clashes

```swift
define(.locked) {
    matching(Enforcement.weak) | when(.coin) | then(.unlocked)
    matching(Reward.negative)  | when(.coin) | then(.locked)
}

// 💥 error: implicit clash
```

The two transitions above *appear* to be different from one another, until we reconsider the inference rules for multiple `Predicate` types:

```swift
define(.locked) {
    matching(Enforcement.weak) | when(.coin) ...
// inferred as:
    matching(Enforcement.weak, and: Reward.positive) | when(.coin) ...
    matching(Enforcement.weak, and: Reward.negative) | when(.coin) ... // 💥 clash 

    matching(Reward.negative) | when(.coin) ...
// inferred as:
    matching(Enforcement.weak,   and: Reward.negative) | when(.coin) ... // 💥 clash
    matching(Enforcement.strong, and: Reward.negative) | when(.coin) ...
```

We can break the deadlock by disambiguating at least one of the statements:

```swift
define(.locked) {
    matching(Enforcement.weak, and: Reward.positive) | when(.coin) | then(.unlocked)
    matching(Reward.negative)                        | when(.coin) | then(.locked)
}

// ✅ inferred as:

define(.locked) {
    matching(Enforcement.weak,   and: Reward.positive) | when(.coin) | then(.unlocked)
//  matching(Enforcement.weak,   and: Reward.negative) ... removed by disambiguation

    matching(Enforcement.weak,   and: Reward.negative) | when(.coin) | then(.locked)
    matching(Enforcement.strong, and: Reward.negative) | when(.coin) | then(.locked)
}
```

In some cases, Swift FSM can break the deadlock without disambiguation:

```swift
define(.locked) {
    matching(Enforcement.weak, and: Reward.positive) | when(.coin) | then(.unlocked)
    matching(Enforcement.weak)                       | when(.coin) | then(.locked)
}

// ✅ inferred as:

define(.locked) {
    matching(Enforcement.weak, and: Reward.positive) | when(.coin) | then(.unlocked)
    matching(Enforcement.weak, and: Reward.negative) | when(.coin) | then(.locked)
}
```

Swift FSM defers to the statement that explicitly specifies the greatest number of predicates - in this case, the first statement `matching(Enforcement.weak, and: Reward.positive)`, which specifies two predicates, versus the second statement’s single predicate `matching(Enforcement.weak)`. 

#### Within-Predicates Clashes

Following the inference logic, connecting different types using the word ‘or’ is not allowed:

```swift
define(.locked) {
    matching(Enforcement.weak, or: Reward.negative) | when(.coin) | then(.unlocked)
}

// ⛔️ does not compile, because it implies:

define(.locked) {
    matching(Enforcement.weak) | when(.coin) | then(.unlocked)
    matching(Reward.negative)  | when(.coin) | then(.unlocked)
}

// 💥 error: implicit clash
```

If we were to call `handleEvent(.coin, predicates: Enforcement.weak, Reward.negative)` with such a table, there would be no reasonable way to decide which transition to perform. Unlike between-predicates implicit clashes, within-predicates clashes are eliminated through the type system.

### Deduplication

```swift
matching(Enforcement.weak)   | when(.pass) /* duplication */ | then(.locked)
matching(Enforcement.strong) | when(.pass) /* duplication */ | then(.alarming)
```

 In this example, `when(.pass)` is duplicated. We can factor this out using a context block:

```swift
when(.pass) {
    matching(Enforcement.weak)   | then(.locked)
    matching(Enforcement.strong) | then(.alarming)
}
```

The full example would now be:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.pass) {
            matching(Enforcement.weak)   | then(.locked)
            matching(Enforcement.strong) | then(.alarming)
        }
                
        when(.coin) | then(.unlocked)
    }
}
```

`then` and `matching` support context blocks in a similar way:

```swift
try fsm.buildTable {
    define(.locked) {
        then(.unlocked) {
            when(.pass) {
                matching(Enforcement.weak)   | doSomething
                matching(Enforcement.strong) | doSomethingElse
            }
        }
    }

// or identically:

    define(.locked) {
        when(.pass) {
            then(.unlocked) {
                matching(Enforcement.weak)   | doSomething
                matching(Enforcement.strong) | doSomethingElse
            }
        }
    }
}
```

```swift
try fsm.buildTable {
    define(.locked) {
        matching(Enforcement.weak) {
            when(.coin) | then(.unlocked) | somethingWeak
            when(.pass) | then(.alarming) | somethingElseWeak
        }

        matching(Enforcement.strong) {
            when(.coin) | then(.unlocked) | somethingStrong
            when(.pass) | then(.alarming) | somethingElseStrong
        }
    }
}
```

The keyword `actions` is also available for function call context blocks:

```swift
try fsm.buildTable {
    define(.locked) {
        actions(someCommonFunction) {
            when(.coin) | then(.unlocked)
            when(.pass) | then(.alarming)
        }
    }
}
```

### Chaining Blocks

```swift
matching(predicate) { 
    // everything in scope matches 'predicate'
}

when(event) { 
    // everything in scope responds to 'event'
}

then(state) { 
    // everything in scope transitions to 'state'
}

actions(functionCalls) { 
    // everything in scope calls 'functionCalls'
}
```

Our context blocks divide into two groups - those that can be logically chained (or AND-ed) together, and those that cannot.

#### Discrete Blocks - `when` and `then`

A transition responds to a single event and transitions to a single state. Therefore multiple `when { }` and `then { }` statements cannot be AND-ed together.

```swift
define(.locked) {
    when(.coin) {
        when(.pass) { } // ⛔️ does not compile
        when(.pass) | ... // ⛔️ does not compile

        matching(.something) | when(.pass) | ... // ⛔️ does not compile

        matching(.something) { 
            when(.pass) { } // ⛔️ does not compile
            when(.pass) | ... // ⛔️ does not compile
        }
    }

    then(.unlocked) {
        then(.locked) { } // ⛔️ does not compile
        then(.locked) | ... // ⛔️ does not compile

        matching(.something) | then(.locked) | ... // ⛔️ does not compile

        matching(.something) { 
            then(.locked) { } // ⛔️ does not compile
            then(.locked) | ... // ⛔️ does not compile
        }
    }      
}

```

Additionally, there is a specific combination of  `when { }` and `then` that does not compile, as there is no situation where, in response to a single event (in this case, `.coin`), there could then be a transition to more than one state, unless a different `Predicate` is given for each. 

```swift
define(.locked) {
    when(.coin) {
        then(.unlocked) | action // ⛔️ does not compile
        then(.locked)   | action // ⛔️ does not compile
    }
}

define(.locked) {
    when(.coin) {
        matching(Enforcement.weak)   | then(.unlocked) | action // ✅
        matching(Enforcement.strong) | then(.locked)   | otherAction // ✅
    }
}
```

#### Chainable Blocks - `matching` and `actions`

There is no logical restriction on the number of predicates or actions per transition, and therefore both can be built up in a chain as follows:

```swift
define(.locked) {
    matching(Enforcement.weak) {
        matching(Reward.positive) { } // ✅ matches Enforcement.weak AND Reward.positive
        matching(Reward.positive) | ... // ✅ matches Enforcement.weak AND Reward.positive
    }

    actions(doSomething) {
        actions(doSomethingElse) { } // ✅ calls doSomething and doSomethingElse
        ... | doSomethingElse // ✅ calls doSomething and doSomethingElse
    }      
}
```

Nested `actions` blocks sum the actions and perform all of them. Nested `matching` blocks are AND-ed together. 

#### Mixing blocks and pipes

Pipes can and must be used inside blocks, whereas blocks cannot be opened after pipes.

```swift
define(.locked) {
    when(.coin) | then(.unlocked) { } // ⛔️ does not compile
    when(.coin) | then(.unlocked) | actions(doSomething) { } // ⛔️ does not compile
    matching(.something) | when(.coin) { } // ⛔️ does not compile
}
```

### Condition Statements

Using Predicates with `matching` syntax is a versatile solution, however in some cases it may bring more complexity than is necessary to solve a given problem (see [Predicate Performance][17] for a description of `matching` overhead).

If you need to make a specific transition conditional at runtime, then the `condition` statement may suffice. Some FSM implementations call this a `guard` statement, however the name `condition` was chosen here as `guard` is a reserved word in Swift.

```swift
define(.locked) {
    condition(complexDecisionTree) | when(.pass) | then(.locked) | lock 
}
```

Here, `complexDecisionTree()` is a function that returns a `Bool`. If it is `true`, the transition is executed, and if it is not, nothing is executed.

The keyword `condition` is syntactically interchangeable with `matching` - it works with pipe and block syntax, and is chainable (conditions are `AND`-ed together).

`matching` and `condition` blocks can also be combined freely:

```swift
define(.locked) {
    condition({ reward == .positive }) {
        matching(Enforcement.weak)   | then(.unlocked) | action
        matching(Enforcement.strong) | then(.locked)   | otherAction
    }
}
```

The disadvantage of `condition` versus `matching` is that it is more limited in the logic it can express:

```swift
define(.locked) {
    when(.coin) {
        matching(Enforcement.weak)   | then(.unlocked) | action
        matching(Enforcement.strong) | then(.locked)   | otherAction
    }
} // ✅ all good here

...

define(.locked) {
    when(.coin) {
        condition { enforcement == .weak   } | then(.unlocked) | action
        condition { enforcement == .strong } | then(.locked)   | otherAction
    }
} // 💥 error: logical clash

```

There is no way to distinguish different `condition` statements, as the `() -> Bool` blocks are inherently opaque. From a logical evaluation point of view, they are invisible. What therefore remains is two statements `define(.locked) { when(.coin) | ... }` that both transition to different states - the FSM has no way to understand which one to call, and must therefore `throw`.

### Runtime Errors

In order to preserve performance, `fsm.handleEvent(event:predicates:)` performs minimal error handling. Therefore, passing in `Predicate` instances that do not appear anywhere in the transition table will not error. Nonetheless, the FSM will be unable to perform any transitions, as it will not contain any statements that match the given, unexpected `Predicate` instance. It is the caller’s responsibility to ensure that the predicates passed to `handleEvent` and the predicates used in the transition table are of the same type and number.

`try fsm.buildTable { }` does perform error handling to make sure the table is syntactically and semantically valid. In particular, it ensures that all `matching` statements are valid, and that there are no duplicate transitions and no logical clashes between transitions.

In addition to the runtime errors thrown by the basic syntax, the expanded syntax also throws the following errors:

#### Matching Error

There are two ways one might inadvertently create an invalid `matching` statement. The first is within a single statement:

```swift
matching(A.a, and: A.b) // 💥 error: cannot match A.a AND A.b simultaneously
matching(A.a, or: B.a, and: A.b) // 💥 error: cannot match A.a AND A.b simultaneously

matching(A.a, and: A.a) // 💥 error: duplicate predicate
matching(A.a, or: A.a)  // 💥 error: duplicate predicate

matching(A.x, or: B.x)... // ⛔️ does not compile: OR types must be the same
matching(A.x, and: A.y)... // 💥 error: cannot match A.x AND A.y simultaneously
```

The second is when AND-ing multiple `matching` statements through the use of blocks:

```swift
matching(A.a, and: B.a) { // ✅
    matching(A.a) // 💥 error: duplicate predicate
    matching(A.b) // 💥 error: cannot match A.a AND A.b simultaneously
}

matching(A.a, or: A.b) { // ✅
    matching(A.a) // 💥 error: duplicate predicate
    matching(A.b) // 💥 error: duplicate predicate
}
```

#### Implicit Clash Error

See [Implicit Clashes][18]

### Predicate Performance

Overview: operations per function call for a table with 100 transitions, 3 `Predicate` types, and 10 cases per `Predicate`

|               | `.eager` | `.lazy` | Schedule         |
| :------------ | :------  | :------ | :--------------- |
| `handleEvent` | 1        | 1-7     | Every transition |
| `buildTable`  | 100,000  | 100     | Once on app load |

#### FSM

Adding predicates has no effect on the performance of `handleEvent()`, but does affect the performance of `fsm.buildTransitions { }`. By default, the FSM preserves `handleEvent()` runtime performance by doing significant work ahead of time when creating the transition table, filling in missing transitions for all implied `Predicate` combinations.

The performance of `fsm.buildTransitions { }` is dominated by this, assuming any predicates are used at all. Because all possible combinations of cases of all given predicates have to be calculated and filtered for each transition, performance is O(m^n\*o) where m is the average number of cases per predicate, n is number of`Predicate` types and o is the number of transitions. 

Using three`Predicate` types with 10 cases each in a table with 100 transitions would therefore require 100,000 operations to compile. In most real-world use cases, this is unlikely to be a problem. If your table is particularly large (see overview above), Swift FSM provides a more performance-balanced alternative for such cases in the form of the `LazyFSM` class.

Note: there is no performance advantage to using the keyword `matching` in fewer versus more transitions in your transition tables. Once the word `matching` is used once, and a `Predicate` instance is passed to `handleEvent()`, the performance implications for the whole table will be as above.

#### Lazy FSM

Passing the `.lazy` argument to `FSM<State, Event>(type: .lazy)` does away with the look-ahead combinatorics algorithm described above. The result is smaller tables internally, and faster table compile time. The cost is at the call to `handleEvent()` where multiple lookup operations are now needed to find the correct transition. 

Performance of`handleEvent()` decreases from O(1) to O(n!), where `n` is the number of `Predicate` types used *regardless of the number of cases*. Inversely, performance of `buildTable { }` increases from O(m^n\*o) to O(n), where n is now the number of transitions. 

Using three `Predicate` types with 10 cases each in a table with 100 transitions would now require 100 operations to compile (down from 100,000 by a factor of 1000). Each call to `handleEvent()` would need to perform between 1 and `3! + 1` or 7 operations (up from 1 by a factor of 1-7). Using more than three `Predicate` types in this case is therefore not advisable.

Overall `LazyFSM` saves a lot more operations than it costs, but that cost is paid at runtime for each transition, rather than as a one-off cost at compile time. In most cases, `FSM` is likely to be the preferred solution, with `LazyFSM` reserved for especially large numbers of transitions and/or `Predicate` cases. If no predicates are used, both implementations exhibit similarly fast performance.

## Troubleshooting

Though Swift FSM runtime errors contain verbose descriptions of the problem, nothing can be done to help with disambiguating compile time errors.

First, familiarity with how `@resultBuilder` works, and the kinds of compile time errors it tends to generate will be very helpful in understanding the errors you may encounter. Almost all Swift FSM-specific compile time errors will be produced by unrecognised arguments to the aforementioned `@resultBuilder`, and unrecognised arguments to the `|` operator overloaded by Swift FSM.

To help, here is a brief list of common errors you are likely to encounter if you try to build something that Swift FSM disallows at compile time:

### Builder Issues

> **No exact matches in call to static method 'buildExpression’**

This is a common compile time error in `@resultBuilder` blocks. It will occur if you feed the block an argument that it does not support. It is useful to remember that each line in such a block is actually an argument fed to a static method.

For example:

```swift
try fsm.buildTable {
     actions(thankyou) { } 
// ⛔️ No exact matches in call to static method 'buildExpression'
}
```

Here an `actions` block is given as an argument to the hidden static function `buildExpression` on the `@resultBuilder` supporting the `buildTable` function. The `define` statement has been skipped, and `actions` returns a type not supported by this outer block, and therefore cannot compile.

### Pipe Issues

> **Cannot convert value of type \<T1\> to expected argument type \<T2\>**

This is common in situations where an unsupported argument is passed to a pipe overload. 

For example:

```swift
try fsm.buildTable {
    define(.locked) {
        then(.locked) | unlock
// ⛔️ Cannot convert value of type 'Syntax.Then<TurnstileState>' to expected argument type 'Internal.MatchingWhenThen'
// ⛔️ No exact matches in call to static method 'buildExpression'
    }
}
```

Here no `matching` and/or `when` statement precede/s the call to `then(.locked)`.  There is no `|` overload that takes as its two arguments the output of `then(.locked)` on the left, and the block `() -> ()` on the right, and therefore cannot compile.

The error unfortunately spits out some internal implementation details that cannot be hidden. Such unavoidable details are marked as such by their location inside the `Internal` namespace.

It also produces a secondary error - as it cannot work out what the output of `then(.locked) | unlock` is, it declares that there is no overload available for `buildExpression`. Fix the underlying `|` error and this error will also disappear.

> **Referencing operator function '|' on 'SIMD' requires that 'Syntax.When\<TurnstileEvent\>' conform to 'SIMD’**

A personal favourite, from this:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.coin) | matching(P.a) | then(.locked) | unlock
// ⛔️ Referencing operator function '|' on 'SIMD' requires that 'Syntax.When<TurnstileEvent>' conform to 'SIMD’
    }
}
```

The order of `when` and `matching` is inverted and not supported. This no different to the previous error, but the compiler interprets the problem differently. It selects a `|` overload from an unrelated module and declares that it is being misused.

The compiler cannot help identify which pipe in the chain is causing the problem. Often it’s simpler just to delete and rewrite the statement rather than trying to figure out what the complaint is.

### Spurious Issues

```swift
try fsm.buildTable {
    let resetable = SuperState {
        when(.reset) | then(.locked)
    }

    define(.locked, adopts: resetable, onEntry: [lock]) {
        when(.coin) | then(.unlocked)
        when(.pass) | then(.alarming)
    }

    define(.unlocked, adopts: resetable, onEntry: [unlock]) {
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)
    }

    define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [🦤])
}
```

This is the original example from [Entry and Exit Actions][19], with one small error inserted at the end. This may or may not produce an appropriate error next to the dodo:

> **Cannot find '🦤' in scope**

What it will also do is generate multiple spurious errors and fixits in the `SuperState` declaration similar to this one:

> **Call to method ‘then’ in closure requires explicit use of ‘self’ to make capture semantics explicit**
> 
> **Reference ‘self.’ explicitly [ Fix ]**
> 
> **Capture 'self' explicitly to enable implicit 'self' in this closure**

Ignore these errors, and if there is no other error shown, you may have to hunt about for the unrecognised argument.









[1]:	https://codecov.io/gh/drseg/swift-fsm
[2]:	https://github.com/unclebob/CC_SMC
[3]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#resultBuilder
[4]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/
[5]:	https://github.com/apple/swift-evolution/blob/main/proposals/0253-callable.md
[6]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/#Trailing-Closures
[7]:	https://github.com/apple/swift-algorithms
[8]:	#nsobject-error
[9]:	https://github.com/drseg/reflective-equality
[10]:	#arrays-of-actions
[11]:	#using-events-to-pass-values
[12]:	#expanded-syntax
[13]:	#expanded-syntax
[14]:	https://github.com/drseg/reflective-equality
[15]:	#predicate-performance
[16]:	#implicit-clashes
[17]:	#predicate-performance
[18]:	#implicit-clashes
[19]:	#entry-and-exit-actions

[image-1]:	https://codecov.io/gh/drseg/swift-fsm/branch/master/graph/badge.svg?token=4UV1D0M80T
[image-2]:	https://img.shields.io/testspace/tests/drseg/drseg:swift-fsm/master
[image-3]:	https://img.shields.io/github/actions/workflow/status/drseg/swift-fsm/swift.yml
[image-4]:	https://img.shields.io/github/license/drseg/swift-fsm
