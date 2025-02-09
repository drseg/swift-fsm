# Swift FSM
[![codecov][image-1]][1] ![Testspace tests][image-2] ![GitHub Workflow Status][image-3] ![GitHub][image-4]

**Friendly Finite State Machine Syntax for Swift on macOS, iOS, tvOS and watchOS**

Inspired by [Uncle Bob's SMC][2] syntax, Swift FSM is a Swift DSL for specifying and operating a Finite State Machine (FSM).

This guide presumes familiarity with FSMs and specifically the SMC syntax linked above. Swift FSM makes liberal use of [`@resultBuilder`][3] blocks,  [operator overloads][4],  [`callAsFunction()`][5], and [trailing closures][6], all in combination with one another - familiarity with these concepts is helpful. 

## Requirements

Swift FSM is a Swift Package for all Apple platforms, available through the Swift Package Manager, and requires Swift 6 or later. It is limited to macOS 15, iOS 18, tvOS 18, and watchOS 11 or later.

Swift 6 Language Mode is recommended - it should work with projects still using Swift 5 language mode, however there will likely be warnings, and possibly compilation errors in some environments (see both [Swift Concurrency][7], and [Swift 6 Language Mode][8]).

It has one dependency - Apple’s [Algorithms][9].

## Basic Syntax

We will mirror SMC’s examples using a subway turnstile system. This turnstile has two states: `Locked`, and `Unlocked`, and two events: `Coin`, and `Pass`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - *Given* we are in the *Locked* state, *when* we get a *Coin* event, *then* we transition to the *Unlocked* state and *invoke* the *unlock* action.
> - *Given* we are in the *Locked* state, *when* we get a *Pass* event, *then* we stay in the *Locked* state and *invoke* the *alarm* action.
> - *Given* we are in the *Unlocked* state, *when* we get a *Coin* event, *then* we stay in the *Unlocked* state and *invoke* the *thankyou* action.
> - *GIven* we are in the *Unlocked* state, *when* we get a *Pass* event, *then* we transition to the *Locked* state and *invoke* the *lock* action.

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

Swift FSM:

```swift
let turnstile = FSM<State, Event>(initialState: .locked)
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

```

Swift FSM (with additional code for context):

```swift
import SwiftFSM

class MyClass: SyntaxBuilder {
    enum State { case locked, unlocked }
    enum Event { case coin, pass }

    let turnstile = FSM<State, Event>(initialState: .locked)

    func myMethod() async throws {
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

        await turnstile.handleEvent(.coin)
    }
}
```

> ```swift
> class MyClass: SyntaxBuilder {
> ```

The `SyntaxBuilder` protocol provides the methods `define`, `when`, and `then` needed to specify transition table. It has two associated types, `State` and `Event`, which must be `Hashable & Sendable`.

> ```swift
> let turnstile = FSM<State, Event>(initialState: .locked)
> ```

`FSM` is generic  over `State` and `Event`. Here we have used an `enum` to specify the initial state of the FSM as `.locked`.

> ```swift
> try turnstile.buildTable {
> ```

`turnstile.buildTable` is a throwing function - though the type system will prevent various illogical statements, there are some semantic issues that can only be detected at runtime.

> ```swift
> define(.locked) {
> ```

The `define` statement roughly corresponds to the ‘Given’ keyword in the natural language description of the FSM. It is expected however that you will only write one `define` per state.

`define` takes two arguments - a `State`, and a `@resultBuilder` block.

> ```swift
> when(.coin) | then(.unlocked) | unlock
> ```

The `|` (pipe) operator binds `when`, `then` and actions into a discrete transition. It feeds the output of the left hand side into the input of the right hand side, as you might expect in a terminal.

As we are inside a `define` block, we take the `.locked` state as a given. We now list our transitions, line by line. `when` we receive a `.coin` event, we will `then` transition to the `.unlocked` state and call the function `unlock`. 

As `unlock` is a reference to a function, it could also be declared as follows:

> ```swift
> when(.coin) | then(.unlocked) | { unlock() //; otherFunction(); etc. }
> ```

Two types of functions are valid as Swift FSM actions:

```swift
@isolated(any) () async -> Void
@isolated(any) (Event) async -> Void
```

Actions that take an `Event` can be useful if you wish to pass an associated value along with an event `enum` to your callback function (see [Using Events to Pass Values][10] for more details on how to implement this, and [Arrays of Actions][11] for ways to combine lists of actions of differing types).

> ```swift
> await turnstile.handleEvent(.coin)
> ```

As `handleEvent` may call an `async` action, `handleEvent` itself must also be `async`.

`FSM` will find the appropriate transition for its current state, call the associated function, and transition to the associated next state. In this case, we call the `unlock` function and transition to the `unlocked` state.  If no transition is found, nothing will happen, and if compiled for debugging, a warning message will print to the console.

##### Arrays of Actions

If you pass an array of actions, you may wish to use the convenience `&` operator overload provided by Swift FSM to enable mixing and matching of different action signatures:

```swift
when(.coin) | then(.unlocked) | first & secondAsync & thirdWithEvent ...
```

This is equivalent (though not technically identical) to the more verbose, but equally valid:

```swift
when(.coin) | then(.unlocked) | { event in await first(); await secondAsync(); thirdWithEvent(event) ... }
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
try turnstile.buildTable {
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

`then()` with no argument means ‘no state change’ - the FSM remains in its current state.  The actions pipe is also optional - if a transition performs no actions, it can be omitted.

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
try turnstile.buildTable {
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

`SuperState` takes the same `@resultBuilder` as `define`, but without a starting state. The starting state is taken from the `define` statement to which it is passed. `define` will then add the transitions declared in each of the `SuperState` instances before the other transitions declared in the `define`. 

If a `SuperState` instance is passed to `define`, the `@resultBuilder` argument is optional.

`SuperState` instances can adopt other `SuperState` instances, and will combine them together as with `define`:

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

Transitions declared in a `SuperState` cannot be overridden by their adopters. The following code is therefore assumed to in error and throws:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | unlock  }

let s2 = SuperState(adopts: s1) { 
    when(.coin) | then(.locked) | beGrumpy // 💥 error: clashing transitions
}

define(.locked, adopts: s1) {
    when(.coin) | then(.locked) | beGrumpy // 💥 error: clashing transitions
}
```

To override a `SuperState` transition, you must make use an `overriding { }` block:

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

Attempting to override within the same `SuperState { }` or `define { }` will throw:

```swift
define(.locked) {
    when(.coin) | then(.locked) | doSomething
    overriding { 
        when(.coin) | then(.locked) | doSomethingElse
    }
}

// 💥 error: duplicate transitions
```

In this scope, the word override has no meaning and is therefore ignored by the error handler. What remains is duplicate transitions, resulting in an error.

#### Override Chains

Overrides follow the usual rules of inheritance. In a chain of overrides, it is the final transition that takes precedence:

```swift
let s1 = SuperState { when(.coin) | then(.unlocked) | a1  }
let s2 = SuperState(adopts: s1) { overriding { when(.coin) | then(.unlocked) | a2 } }
let s3 = SuperState(adopts: s2) { overriding { when(.coin) | then(.unlocked) | a3 } }
let s4 = SuperState(adopts: s3) { overriding { when(.coin) | then(.unlocked) | a4 } }

define(.locked, adopts: s4) {
    overriding { when(.coin) | then(.unlocked) | a5 } // ✅ overrides all others
}

turnstile.handleEvent(.coin) // 'a5' is called
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
try turnstile.buildTable {
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

`onEntry` and `onExit` specify arrays of actions to be performed when entering or leaving the defined state. These require array syntax rather than more convenient varargs, owing to limitations in Swift’s matching algorithm for functions that take multiple closure arguments. 

As the array is heterogeneous (it can include either of the two action types), a special postfix operator `*` is provided to convert a single one of these into an array of `AnyAction`.

```swift
_ = unlock* // preferred syntax, same as...
_ = Array(unlock) // same as...
_ = [AnyAction(unlock)]

_ = unlock & thankyou // preferred syntax, same as...
_ = AnyAction(unlock) & thankyou // same as...
_ = AnyAction(unlock) & AnyAction(thankyou) // same as...
_ = [AnyAction(unlock), AnyAction(thankyou)]
```

`SuperState` instances also accept entry and exit actions:

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

In SMC, entry and exit actions are always invoked even if the state does not change. The unlock entry action would therefore always be called on all transitions into the `Unlocked` state. 

Swift FSM’s default behaviour is to invoke entry and exit actions **only if there is a state change**. In the example above, this means that, in the `.unlocked` state, after a `.coin` event, `unlock` is *not* called.

Swift FSM will match SMC if you pass `.executeAlways` to `FSM.init`. The default is `.executeOnChangeOnly` and is not required.

```swift
FSM<State, Event>(initialState: .locked, actionsPolicy: .executeAlways)
```

### Syntax Order

All statements must be made in the form `define { when | then | actions }`. See [Expanded Syntax][12] for exceptions to this rule.

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

Actions can receive the event that resulted in them being called. SwiftFSM requires a special struct `FSMValue<T>` and protocol `EventWithValues` that work together to enable you to do this.

```swift
enum Event: EventWithValues {
    case .coin(FSMValue<Int>), ...

    var coinValue: Int? {
        guard case .coin(let amount) = event else { return nil }
        return amount.wrappedValue
    }
}

func main() throws {
    try turnstile.buildTable(initialState: .locked) {
        define(.locked) {
            when(.coin(.any)) | then(.verifyingPayment) | verifyPayment
            // here we use .any to match any value
        }
    }

    try turnstile.handleEvent(.coin(50))
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

 `when(.coin(.any))` works polymorphically, matching against any value inside `.coin(someValue)` and passing `someValue` on to the `verifyPayment` function. 

Without the combination of `EventWithValues` and `FSMValue<T>`, the table would have to be written as follows:

```swift
try turnstile.buildTable(initialState: .locked) {
    define(.locked) {
        when(.coin(1)) | then(.verifyingPayment) | verifyPayment
        when(.coin(2)) | then(.verifyingPayment) | verifyPayment
        when(.coin(3)) | then(.verifyingPayment) | verifyPayment
        when(.coin(4)) | then(.verifyingPayment) | verifyPayment
        ... // and so on for all relevant values
    }
}
```

By using `EventWithValues.any`, the transition to `.verifyingPayment` will be activated when a `.coin` event is received, no matter the wrapped value. That wrapped value is then passed into the `verifyPayment` function where it can be examined. `FSMValue` provides a convenience `var wrappedValue: T?`, which returns an optional value (potentially nil if it is called on a `.any` instance or if `T` is optional and nil).

#### Literal Expression Implementations

FSMValue conforms to `ExpressibleByIntegerLiteral`, `ExpressibleByFloatLiteral`, `ExpressibleByArrayLiteral`, `ExpressibleByDictionaryLiteral`, `ExpressionByNilLiteral`, and `ExpressionByStringLiteral` forwarding to the wrapped type where relevant. It also forwards conformances to `Equatable`, `Comparable`, and `AdditiveArithmetic` where relevant, as well as `RandomAccessCollection` and its parent protocols for Arrays, and subscript access for Dictionaries. It forwards `CustomStringConvertible`, which also covers most uses of `ExpressibleByStringInterpolation`.

A few examples:

```swift
let s: FSMValue<String> = "1" // equivalent to .some("1")
let i: FSMValue<Int> = 1 // equivalent to .some(1)
let ai: FSMValue<[Int]> = [1] // equivalent to .some([1])

_ = s + "1" // "11"
_ = i + 1 // 2
_ = ai[0] // 1
_ = ai[0] == i // true
_ = ai[0] > i // false
_ = "\(i)\(s)" // "11"
```

**Warning**: where forward operations are available on the wrapped type, be aware that this will crash if you attempt to access a value on a `.any` instance (much like force unwrapping a nil optional - in this sense, `.any` is a null value). `.any` should therefore only appear inside a define statement - there are no circumstances in which it would be useful or meaningful to pass such an event with `FSMValue.any` to `handleEvent`.

You should always unwrap `FSMValue<T>` instances before continuing - indeed, all convenience methods that return a value return an instance of `T` and *not* of `FSMValue<T>`. 

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

If the `if/else` block were evaluated by the FSM at transition time, this would be useful. However what we are doing is *compiling* our state transition table (SMC stands for State Machine _Compiler_). The use of `if` and `else` in this manner is akin to using `#if` and `#else` - only one transition or the other will be compiled.

See [Expanded Syntax][13] for an alternative system for evaluating conditional statements at runtime rather than compile time.

### Swift Concurrency

Swift FSM does not make demands on its clients’ concurrency handling. The public methods on the `FSM` class are polymorphically isolated to the caller’s `Actor` (if there is one), or no `Actor` at all. This is achieved by including the argument `isolation: isolated (any Actor)? = #isolation` in all public method signatures.

Swift FSM works transparently in any concurrency or non-concurrency environment. It is however _technically_ possible (though impractical) to call each of the `FSM` class’ public methods from a different actor, as actor polymorphism currently works at an individual function level, rather than at a class level. 

`FSM` has an optional runtime concurrency checker that fails a `precondition` check if you try to call its methods from conflicting concurrency environments. The can be enabled by passing the `enforceConcurrency: true` to `FSM.init`. This check only runs when building for debugging.

```swift
class MyClass {
    let fsm: FSM<Int, Int>
    init(fsm: FSM<Int, Int>) {
        self.fsm = fsm
    }
    
    func one() async { await fsm.handleEvent(1) }
    
    @MainActor
    func two() async { await fsm.handleEvent(1) }
}

let fsm = FSM<Int, Int>(initialState: 1, enforceConcurrency: true)
let c = MyClass(fsm: fsm)

try fsm.buildTable {
    define(1) { when(2) | then() }
}             
// ✅ First call sets the actor for future calls
await c.one() 
// ✅ Same 'NonIsolated' as first call
await c.two() 
// 💥 Concurrency violation: handleEvent called by MainActor (expected NonIsolated)
```

#### Working on the Main Actor

Though `FSM` runs on the main actor if its methods are called from it, until Swift provides a way of unifying polymorphic actor behaviour across an entire class, Swift FSM also provides a convenience wrapper `FSM<State, Event>.OnMainActor`, annotated `@MainActor` to allow the compiler to enforce isolation without having to use the optional runtime checker.

In most situations however, there will be no difference between the behaviour of `FSM` or `FSM.OnMainActor` in a main actor context - `OnMainActor` simply guards against an unlikely edge case at compile time. 

Some of the nuances of the system (when compiled in Swift 6 Language Mode):

```swift
@MainActor
class MyMainActorClass {
    func myMethod() {
        // ✅ Called with Main Actor isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ✅ Called with Main Actor isolation
        let mainActorFSM = FSM<Int, Int>.OnMainActor(initialState: 1)
    }
    
    func myAsyncMethod() async {
        // ✅ Called with Main Actor isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ✅ Called with Main Actor isolation
        let mainActorFSM = FSM<Int, Int>.OnMainActor(initialState: 1)
    }
}

class MyNonIsolatedClass {
    func myMethod() {
        // ✅ Called without isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ⛔️ Call to main actor-isolated initializer 'init(type:initialState:actionsPolicy:)' in a synchronous nonisolated context
        let mainActorFSM = FSM<Int, Int>.OnMainActor(initialState: 1)
    }
    
    func myAsyncMethod() async {
        // ✅ Called without isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ✅ Called with Main Actor isolation
        let mainActorFSM = await FSM<Int, Int>.OnMainActor(initialState: 1)
    }
    
    @MainActor
    func myMainActorMethod() {
        // ✅ Called with Main Actor isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ✅ Called with Main Actor isolation
        let mainActorFSM = FSM<Int, Int>.OnMainActor(initialState: 1)
    }
}

actor MyCustomActor {
    func myMethod() {
        // ✅ Called with MyCustomActor isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ⛔️ Call to main actor-isolated initializer 'init(type:initialState:actionsPolicy:)' in a synchronous nonisolated context
        let mainActorFSM = FSM<Int, Int>.OnMainActor(initialState: 1)
    }
    
    func myAsyncMethod() async {
        // ✅ Called with MyCustomActor isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ✅ Called with Main Actor isolation
        let mainActorFSM = await FSM.OnMainActor<Int, Int>(initialState: 1)
    }
    
    @MainActor
    func myMainActorMethod() {
        // ✅ Called with Main Actor isolation
        let fsm = FSM<Int, Int>(initialState: 1)
        
        // ✅ Called with Main Actor isolation
        let mainActorFSM = FSM<Int, Int>.OnMainActor(initialState: 1)
    }
}
```

### Runtime Errors

Most Swift FSM function calls and initialisers take additional ‘magic’ parameters `file: String = #file`  and `line: Int = #line`. Some also take `isolation: isolated (any Actor)? = #isolation`.

As these cannot be hidden, note that there is unlikely to be any reason to override these default arguments with alternate values.

#### Empty Blocks

All blocks must contain at least one statement:

```swift
try turnstile.buildTable { } //💥 error: empty table
try turnstile.buildTable {
    define(.locked) { } // 💥 error: empty block
}
```

#### Duplicate Transitions

Transitions are duplicates if they share the same start state, event, and next state:

```swift
try turnstile.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.coin) | then(.unlocked) | lock
    }
}

// 💥 error: duplicate transitions
```

#### Logical Clashes

Transitions clash when they share the same start state and event, but their next states differ:

```swift
try turnstile.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.coin) | then(.locked)   | lock
    }
}

// 💥 error: logical clash
```

Though the two transitions are distinct, they cannot co-exist - the `.coin` event must lead either to the `.unlocked` state or to the `.locked` state. It cannot lead to both.

#### FSMValue - incorrect use of .any

Because `.any` matches all cases, the following would throw:

```swift
try turnstile.buildTable(initialState: .locked) {
    define(.locked) {
        when(.coin(.any)) | then(.verifyingPayment) | verifyPayment
        when(.coin(50)    | then(.unlocked)         | pass
    }
} 

//💥 error: logical clash
```

The `.any` case already includes all cases, creating ambiguity. It would be possible to write the following:

```swift
try turnstile.buildTable(initialState: .locked) {
    define(.locked) {
        when(.coin(20) | then(.verifyingPayment) | verifyPayment
        when(.coin(50) | then(.unlocked)         | pass
    }
} 

// ✅ transitions are logically distinct
```

#### Duplicate `buildTable` Calls

Additional calls to `turnstile.buildTable { }` will throw a `TableAlreadyBuiltError`.

### Performance

Each call to `handleEvent()` has O(1) performance. Nevertheless, it still has 2-3x the operating overhead of an equivalent nested switch case statement. Swift FSM trades performance for convenience, and is not suitable for resource constrained environments.

## Expanded Syntax

Whilst Swift FSM matches most of the syntax of SMC, it also introduces some new possibilities of its own.

### Example

Let’s imagine an extension to our turnstile rules: at some times, we want to enforce the ‘everyone pays’ rule by entering the alarming state if a `.pass` is detected while still `.locked` . In others, perhaps at rush hour, we want to be more permissive.

We could implement a time of day check elsewhere in the system, perhaps like this:

```swift
try turnstile.buildTable {
    ...
    define(.locked) {
        when(.pass) | then(.alarming) | handleAlarm
    }
    ...
}

// elsewhere in the system...

enum Enforcement: Predicate { case weak, strong }

let enforcement = Enforcement.weak

func handleAlarm() {
    switch enforcement {
    case .weak: smile()
    case .strong: defconOne()
    }
}
```

But we now have some aspects of our state transition logic declared inside the transition table, and other aspects declared elsewhere. And we still transition to the `.alarming` state, regardless of the `Enforcement` policy. What if different policies called for entirely different transitions?

We might introduce extra events to differentiate between the new policies:

```swift
try turnstile.buildTable {
    ...
    define(.locked) {
        when(.passWithEnforcement)    | then(.alarming) | defconOne
        when(.passWithoutEnforcement) | then(.locked)   | smile
    }
    ...
}
```

Now we can call different functions and transition to different states, depending on the enforcement policy, whilst keeping our logic inside the transition table.

Every transition that originally responded to the `.pass` event now needs to be written twice, once for each of the two new versions of this event, *even if they are both identical*. The state transition table is going to become unmanageably long, and littered with duplication. 

**The Swift FSM Solution**

```swift
import SwiftFSM

class MyClass: ExpandedSyntaxBuilder {
    enum State { case locked, unlocked }
    enum Event { case coin, pass }
    enum Enforcement: Predicate { case weak, strong }

    let fsm = FSM<State, Event>(initialState: .locked)

    func myMethod() throws {
        try turnstile.buildTable {
            ...
            define(.locked) {
                matching(Enforcement.weak)   | when(.pass) | then(.locked)   | smile
                matching(Enforcement.strong) | when(.pass) | then(.alarming) | defconOne
                
                when(.coin) | then(.unlocked)
            }
            ...
       }
        
       turnstile.handleEvent(.pass, predicates: Enforcement.weak)
    }
}
```

We have introduced the function `matching`, and two protocols, `ExpandedSyntaxBuilder` and `Predicate`. 

> ```swift
> define(.locked) {
>     matching(Enforcement.weak)   | when(.pass) | then(.locked)   | smile
>     matching(Enforcement.strong) | when(.pass) | then(.alarming) | defconOne
>                 
>     when(.coin) | then(.unlocked) | unlock
> }
> ```

Given that we are in the `.locked` state:
- If `Enforcement` is `.weak`, when we get a `.pass`, transition to `.locked` and `smile`
- If `Enforcement` is `.strong`, when we get a `.pass`, transition to `.alarming` and `defconOne`
- *Regardless* of `Enforcement`, when we get a `.coin`, transition to `.unlocked` and `unlock`

Only those statements that depend upon the `Enforcement` policy know it has been added - preexisting statements continue to work unchanged.

### ExpandedSyntaxBuilder and Predicate

`ExpandedSyntaxBuilder` implements `SyntaxBuilder` with the same requirements. `Predicate` requires the conformer to be `Hashable, Sendable` and `CaseIterable`. It is possible to use any type, but in practice, the `CaseIterable` requirement is likely to limit `Predicate` to `Enums` without associated types.

### Implicit Matching Statements

> ```swift
> when(.coin) | then(.unlocked)
> ```

When `Predicate` is specified, it is inferred from the transition’s context. The scope for inference is between the braces of `turnstile.buildTable { }`. This is one reason why this function can only be called once.  

In our example, the type `Enforcement` appears in a `matching` statement elsewhere in the table, and Swift FSM will infer the absent `matching` statements:

```swift
when(.coin) | then(.unlocked)

// is inferred to mean:

matching(Enforcement.weak)   | when(.coin) | then(.unlocked)
matching(Enforcement.strong) | when(.coin) | then(.unlocked)
```

Transitions are are therefore `Predicate` agnostic by default, matching any `Predicate` unless otherwise specified. `matching` is an optional modifier that *constrains* the transition to one or more specific `Predicate` cases.

### Multiple Predicates

There is no limit to the number of `Predicate` types that can be used (see [Predicate Performance][14] for practical limitations).

```swift
enum Enforcement: Predicate { case weak, strong }
enum Reward: Predicate { case positive, negative }

try turnstile.buildTable {
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

await turnstile.handleEvent(.pass, predicates: Enforcement.weak, Reward.positive)
```

The same inference rules still apply:

```swift
when(.coin) | then(.unlocked) | unlock

// types Enforcement and Reward appear elsewhere in context
// when(.coin) | then(.unlocked) is now equivalent to:

matching(Enforcement.weak,   and: Reward.positive) | when(.coin) | then(.unlocked) | unlock
matching(Enforcement.strong, and: Reward.positive) | when(.coin) | then(.unlocked) | unlock
matching(Enforcement.weak,   and: Reward.negative) | when(.coin) | then(.unlocked) | unlock
matching(Enforcement.strong, and: Reward.negative) | when(.coin) | then(.unlocked) | unlock
```

The result of the call to `handleEvent` , assuming the current state is `.locked`, will be to stay in the `.locked` state and call the `lock` function.

#### Compound Matching Statements

Multiple predicates can be combined in a single `matching` statement, by populating the `and: Predicate...` and `or: Predicate...` arguments.

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

turnstile.handleEvent(.coin, predicates: A.x, B.x, C.x)
```

`matching(and:)` means that we expect both predicates to be present at the same time, whereas `mathing(or:)` means that we expect any and only one to be present.

Swift FSM expects exactly one instance of each `Predicate` type present in the table to be passed to `handleEvent`, as in the example, where `turnstile.handleEvent(.coin, predicates: A.x, B.x, C.x)` contains a single instance of types `A`, `B` and `C`. Accordingly, `A.x AND A.y` should never occur - only one can be present. Therefore, predicates passed to `matching(and:)` must all be of a different type.

`matching(or:)` specifies multiple possibilities for a single `Predicate` type. Predicates joined by `or` must therefore all be of the same type, and attempting to pass different `Predicate` types to `matching(or:)` will not compile (see [Implicit Clashes][15] for more information on this limitation).

### Implicit Clashes

#### Between-Predicates Clashes

```swift
define(.locked) {
    matching(Enforcement.weak) | when(.coin) | then(.unlocked)
    matching(Reward.negative)  | when(.coin) | then(.locked)
}

// 💥 error: implicit clash
```

The two transitions *appear* to be different, however:

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

Swift FSM prioritises the statement that specifies the greatest number of predicates - in this case, the first statement `matching(Enforcement.weak, and: Reward.positive)` specifies two predicates, trumping the second statement’s single predicate `matching(Enforcement.weak)`. 

In essence, `Reward.positive` has already been ‘claimed’ by the more explicit transition, leaving only the leftover `Reward.negative` for the less explicit transition. 

#### Within-Predicates Clashes

Connecting different types by ‘OR’ is not allowed:

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

### Deduplication With Context Blocks

```swift
matching(Enforcement.weak)   | when(.pass) /* duplication */ | then(.locked)
matching(Enforcement.strong) | when(.pass) /* duplication */ | then(.alarming)
```

 `when(.pass)` is duplicated. We can factor this out using a context block:

```swift
when(.pass) {
    matching(Enforcement.weak)   | then(.locked)
    matching(Enforcement.strong) | then(.alarming)
}
```

The full example would now be:

```swift
try turnstile.buildTable {
    define(.locked) {
        when(.pass) {
            matching(Enforcement.weak)   | then(.locked)
            matching(Enforcement.strong) | then(.alarming)
        }
                
        when(.coin) | then(.unlocked)
    }
}
```

`then` and `matching` also support context blocks:

```swift
try turnstile.buildTable {
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
try turnstile.buildTable {
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

`actions` is also available for context blocks:

```swift
try turnstile.buildTable {
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

Context blocks divide into two groups - those that can be logically chained (or AND-ed), and those that cannot.

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

There is a specific combination of  `when { }` and `then` that does not compile, as there is no situation where, in response to a single event (in this case, `.coin`), there could then be a transition to more than one state, unless a different `Predicate` is given for each.

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

These can be built up in a chain as follows:

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

Nested `actions` blocks sum the actions and perform all of them.

Nested `matching` statements are combined by AND-ing them together, which makes it possible inadvertently to create conflicts.

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

Using Predicates is a versatile solution, however in some cases it may bring more complexity than is necessary to solve a given problem (see [Predicate Performance][16] for a description of `matching` overhead).

If you need to make a specific transition conditional at runtime, the `condition` statement may suffice.

```swift
define(.locked) {
    condition(complexDecisionTree) | when(.pass) | then(.locked) | lock 
}
```

`complexDecisionTree()` is a function that returns a `Bool`. If `true`, the transition is executed, and if not, nothing is executed.

`condition` is syntactically interchangeable with `matching` - it works with pipe and block syntax, and is chainable.

`matching` and `condition` can be combined freely:

```swift
define(.locked) {
    condition({ reward == .positive }) {
        matching(Enforcement.weak)   | then(.unlocked) | action
        matching(Enforcement.strong) | then(.locked)   | otherAction
    }
}
```

`condition` is more limited than `matching` in the logic it can express:

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

There is no way to distinguish different `condition` statements, as `() -> Bool` is opaque. What remains is two statements `define(.locked) { when(.coin) | ... }` that both transition to different states - the FSM has no way to decide which one to call, and will therefore `throw`.

### Runtime Errors

To preserve performance, `turnstile.handleEvent(event:predicates:)` has no error handling. Therefore, passing in `Predicate` instances that do not appear anywhere in the transition table will not error. Nonetheless, the FSM will be unable to perform any transitions, as it will not contain any statements that match the unexpected `Predicate`. It is the caller’s responsibility to ensure that predicates passed to `handleEvent` and predicates used in the transition table are of the same type and number.

`try turnstile.buildTable { }` performs significant error handling to make sure the table is syntactically and semantically valid.

Expanded syntax also throws the following additional errors:

#### Matching Error

There are two ways to create an invalid `matching` statement. The first is with a single statement:

```swift
matching(A.a, and: A.b) // 💥 error: cannot match A.a AND A.b simultaneously
matching(A.a, or: B.a, and: A.b) // 💥 error: cannot match A.a AND A.b simultaneously

matching(A.a, and: A.a) // 💥 error: duplicate predicate
matching(A.a, or: A.a)  // 💥 error: duplicate predicate

matching(A.x, or: B.x)... // ⛔️ does not compile: OR types must be the same
matching(A.x, and: A.y)... // 💥 error: cannot match A.x AND A.y simultaneously
```

The second is AND-ing multiple `matching` statements in blocks:

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

See [Implicit Clashes][17]

### Predicate Performance

Overview: operations per function call for a table with 100 transitions, 3 `Predicate` types, and 10 cases per `Predicate`

|               | `.eager` | `.lazy` | Schedule         |
| :------------ | :------- | :------ | :--------------- |
| `handleEvent` | 1        | 1-7     | Every transition |
| `buildTable`  | 100,000  | 100     | Once on app load |

#### FSM

Adding predicates does not affect the performance of `handleEvent()`, but does slow the performance of `fsm.buildTable { }`. By default, the ‘eager’ FSM preserves `handleEvent()` runtime performance of O(1) by doing significant work ahead of time when creating the transition table, filling in missing transitions for all implied `Predicate` combinations.

`fsm.buildTable { }` is dominated by this ‘filling out’ of the table, assuming any predicates are used at all. Because all possible combinations of cases of all given predicates have to be calculated and filtered for each transition, performance is O(m^n\*o) where m is the average number of cases per predicate, n is number of`Predicate` types and o is the number of transitions. 

Using three`Predicate` types with 10 cases each in a table with 100 transitions would therefore require 100,000 operations to compile. In most real-world use cases, this is unlikely to be a problem.

Note: there is no advantage to using the keyword `matching` less often. Once the word `matching` is used, and a `Predicate` instance is passed to `handleEvent()`, the performance implications for the whole table will be the same regardless of how many times it is used.

#### Lazy FSM

If your table is particularly large (see overview above), Swift FSM provides a more balanced alternative. Passing the `.lazy` argument to `FSM<State, Event>(type: .lazy)` does away with the look-ahead algorithm, resulting in smaller tables internally and faster table compile time. The cost is multiple table lookup operations at each call to `handleEvent()`.

Performance of `handleEvent()` decreases from O(1) to O(n!), where `n` is the number of `Predicate` _types_ used regardless of the number of cases. Conversely, performance of `buildTable { }` increases from O(m^n\*o) to O(n), where `n` is the number of transitions. 

Using three `Predicate` types with 10 cases each in a table with 100 transitions would now require 100 operations to compile (down from 100,000 for `.eager`). Each call to `handleEvent()` would need to perform between 1 and `3! + 1` or 7 operations (up from 1 for `.eager`). Using more than three `Predicate` types in this case is therefore not advisable as performance decreases factorially.

In most cases, `.eager` is the preferred solution, with `.lazy` reserved for especially large numbers of transitions and/or `Predicate` cases. 

If no predicates are used, both implementations are identical.

## Troubleshooting

Though Swift FSM runtime errors contain verbose descriptions of the problem, little can be done to help with disambiguating compiler errors.

Familiarity with how `@resultBuilder` works, and the kinds of compile time errors it tends to generate will be helpful in understanding any errors you may encounter. Almost all Swift FSM-specific compile time errors will be produced by unrecognised arguments to the aforementioned `@resultBuilder`, and unrecognised arguments to the heavily overloaded `|` operator.

To help, here is a brief list of common errors you are likely to encounter if you try to build something that Swift FSM disallows at compile time:

### Builder Issues

> **No exact matches in call to static method 'buildExpression’**

This is a common compile time error in `@resultBuilder` blocks. It will occur if you feed the block an argument that it does not support. It is useful to remember that each line in such a block is actually an argument fed to a static method.

For example:

```swift
try turnstile.buildTable {
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
try turnstile.buildTable {
    define(.locked) {
        then(.locked) | unlock
// ⛔️ Cannot convert value of type 'Internal.Then<TurnstileState>' to expected argument type 'Internal.MatchingWhenThen'
// ⛔️ No exact matches in call to static method 'buildExpression'
    }
}
```

No `matching` and/or `when` statement precedes the call to `then(.locked)`.  There is no `|` overload that takes the output of `then(.locked)` on the left, and the block `() -> ()` on the right, and therefore does not compile.

The error unfortunately spits out some internal implementation details that cannot be hidden (see below)

It also produces a secondary error - as it cannot work out what the output of `then(.locked) | unlock` is, it declares that there is no overload available for `buildExpression`. Fix the underlying `|` error and this error will also disappear.

> **Referencing operator function '|' on 'SIMD' requires that 'Internal.When\<TurnstileEvent\>' conform to 'SIMD’**

```swift
try turnstile.buildTable {
    define(.locked) {
        when(.coin) | matching(P.a) | then(.locked) | unlock
// ⛔️ Referencing operator function '|' on 'SIMD' requires that 'Internal.When<TurnstileEvent>' conform to 'SIMD’
    }
}
```

The order of `when` and `matching` is inverted and not supported. This is no different to the previous error, but the compiler interprets the problem differently. It selects a `|` overload from an unrelated module and declares that it is being misused.

The compiler cannot help identify which pipe in the chain is causing the problem. Often it’s simpler just to delete and rewrite the statement rather than trying to figure out what the complaint is.

### Spurious Issues

```swift
try turnstile.buildTable {
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

This is the original example from [Entry and Exit Actions][18], with one small error inserted at the end. This may or may not produce an appropriate error next to the dodo:

> **Cannot find '🦤' in scope**

What it will also do is generate multiple spurious errors and fixits in the `SuperState` declaration similar to this one:

> **Call to method ‘then’ in closure requires explicit use of ‘self’ to make capture semantics explicit**
> 
> **Reference ‘self.’ explicitly [ Fix ]**
> 
> **Capture 'self' explicitly to enable implicit 'self' in this closure**

Ignore these errors, and if there is no other error shown, you may have to hunt about for the unrecognised argument.

### Swift 6 Language Mode

This project is dominated by its need to capture client functions. The concurrency rules introduced through the latter part of Swift 5 evolution have increasingly restricted the ways in which this can be done in order to prevent of data races.

The rules have not been consistent, with Swift 5.10 behaving more restrictively than Swift 6.0 in some cases. Because of this, Swift FSM is only guaranteed to work as intended when using Swift 6 Language Mode.

Using Swift 5 Language Mode will likely work, however is not guaranteed.

### Exposed Internals

In order to build up the syntax, each of the methods declared in `SyntaxBuilder` and `ExpandedSyntaxBuilder` needs to return an intermediate object used by the FSM to chain together each entry in the transition table. ‘Something’ has to be output by each call to `|`, even though that something is irrelevant to the user. Though their implementations are marked `internal` and should not be accessible or modifiable, you may see reference to some of these objects in compilation errors and autocomplete suggestions.

## Code Quality

Swift FSM is written using test driven development, and as a non-UI framework maintains a requirement of 100% code coverage. Coverage does not guarantee test quality, however _lack_ of coverage does guarantee _lack_ of test quality.

The exception to the ‘100%’ rule is code that is not executed - Swift’s rejection of abstract classes still requires the `fatalError("subclasses must implement")` pattern where protocols either won’t do the job or won’t do it cleanly. 

Nonetheless, the project still tries to respect standard Swift’s practices wherever possible, and wherever those practices do not impact testability or create duplication. If so, testability and deduplication always win. Over time, the goal is to refactor ‘non-Swifty’ solutions to ‘Swiftier’ solutions when a reasonable opportunity to do so presents itself.

If you do encounter executed code that is not covered by tests, please file an issue, as lack of coverage is a serious bug and process failure.








[1]:	https://codecov.io/gh/drseg/swift-fsm
[2]:	https://github.com/unclebob/CC_SMC
[3]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#resultBuilder
[4]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/
[5]:	https://github.com/apple/swift-evolution/blob/main/proposals/0253-callable.md
[6]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/#Trailing-Closures
[7]:	#swift-concurrency
[8]:	#swift-6-language-mode
[9]:	https://github.com/apple/swift-algorithms
[10]:	#using-events-to-pass-values
[11]:	#arrays-of-actions
[12]:	#expanded-syntax
[13]:	#expanded-syntax
[14]:	#predicate-performance
[15]:	#implicit-clashes
[16]:	#predicate-performance
[17]:	#implicit-clashes
[18]:	#entry-and-exit-actions

[image-1]:	https://codecov.io/gh/drseg/swift-fsm/branch/master/graph/badge.svg?token=4UV1D0M80T
[image-2]:	https://img.shields.io/testspace/tests/drseg/drseg:swift-fsm/master
[image-3]:	https://img.shields.io/github/actions/workflow/status/drseg/swift-fsm/swift.yml
[image-4]:	https://img.shields.io/github/license/drseg/swift-fsm