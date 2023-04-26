# Swift FSM
**Friendly Finite State Machine Syntax for Swift, iOS and macOS**

Inspired by [Uncle Bob's SMC][1] syntax, Swift FSM provides a pure Swift syntax for declaring and operating a Finite State Machine (FSM). Unlike Uncle Bob’s SMC, the FSM is declared inside your Swift code, rather than as a separate text file, and compiles and runs natively as part of your project’s code.

This guide is reasonably complete, but does presume some familiarity with FSMs and specifically the SMC syntax linked above. Swift FSM makes liberal use of [`@resultBuilder`][2] blocks,  [operator overloads][3] and  [`callAsFunction()`][4], all in combination with one another - familiarity with these concepts may also be helpful.

## Contents

- [Requirements][5]
- [Basic Syntax][6]
	- [Optional Arguments][7]
	- [Super States][8]
	- [Entry and Exit Actions][9]
	- [Syntax Order][10]
	- [Syntax Variations][11]
	- [Syntactic Sugar][12]
	- [Runtime Errors][13]
	- [Performance][14]
- [Expanded Syntax][15]
	- [Example][16]
	- [ExpandedSyntaxBuilder and Predicate][17]
	- [Implicit Matching Statements][18]
	- [Multiple Predicates][19]
	- [Implicit Clashes][20]
	- [Deduplication][21]
	- [Chained Blocks][22]
	- [Complex Predicates][23]
	- [Condition Statements][24]
	- [Runtime Errors][25]
	- [Predicate Performance][26]
- [Troubleshooting][27]

## Requirements

Swift FSM is a Swift package, importable through the Swift Package Manager, requiring macOS 13 and/or iOS 16 or later, alongside Swift 5.7 or later. 

It depends on two further packages - Apple’s [Algorithms][28], and ([in one very small and specific place][29]) my own [Reflective Equality][30]

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

        fsm.handleEvent(.coin)
    }
}
```

> ```swift
> class MyClass: SyntaxBuilder {
> ```

The `SyntaxBuilder` protocol provides the methods `define`, `when`, and `then` necessary to build the transition table. It has two associated types, `State` and `Event`, which must be `Hashable`.

> ```swift
> let fsm = FSM<State, Event>(initialState: .locked)
> ```

`FSM` is generic  over `State` and `Event`.  As with `SyntaxBuilder`, `State` and `Event` must be `Hashable`. Here we have used an `Enum`, specifying the initial state of the FSM as `.locked`.

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

The `|` (pipe) operator binds transitions together. It feeds the output of the left hand side into the input of the right hand side, as you might expect in a terminal.

> ```swift
> fsm.handleEvent(.coin)
> ```

The `FSM` instance will look up the appropriate transition for its current state, call the associated function, and transition to the associated next state. In this case, the `FSM` will call the `unlock` function and transition to the `unlocked` state.  If no transition is found, it will do nothing.

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
        when(.reset) | then()          | { alarmOff(); lock() }
    }

    define(.unlocked) {
        when(.reset) | then(.locked)   | { alarmOff(); lock() }
        when(.coin)  | then(.unlocked) | thankyou
        when(.pass)  | then(.locked)   | lock
    }

    define(.alarming) {
        when(.coin)  | then()
        when(.pass)  | then()
        when(.reset) | then(.locked) | { alarmOff(); lock() }
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
        when(.reset) | then(.locked) | { alarmOff(); lock() }
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

`SuperState`  takes a `@resultBuilder` block like `define`, however it does not take a starting state. The starting state is taken from the `define` statement to which it is passed. Passing `SuperState` instances to a `define` call will add the transitions declared in each of the `SuperState` instances to the other transitions declared in the `define`. 

If a `SuperState` instance is given, the `@resultBuilder` argument to `define` is optional.

`SuperState` instances themselves can accept other `SuperState` instances, and will combine them together in the same way as `define`:

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

**Important** - SMC allows for both abstract (without a given state) and concrete (with a given state) Super States. It also allows for overriding transitions declared in a Super State. Swift FSM on the other hand only allows abstract Super States, defined using the `SuperState` struct, and any attempt to override a Super State transition will result in a duplicate transition error.

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

    define(.locked, adopts: resetable, onEntry: [lock]) {
        when(.coin) | then(.unlocked)
        when(.pass) | then(.alarming)
    }

    define(.unlocked, adopts: resetable, onEntry: [unlock]) {
        when(.coin) | then(.unlocked) | thankyou
        when(.pass) | then(.locked)
    }

    define(.alarming, adopts: resetable, onEntry: [alarmOn], onExit: [alarmOff])
}
```

`onEntry` and `onExit` are the final arguments to `define` and specify an array of entry and exit actions to be performed when entering or leaving the defined state. Unfortunately these cannot be varargs, and must use explicit array syntax instead to work around limitations in Swift’s matching algorithm for functions that take multiple closure arguments.

`SuperState` instances can also accept entry and exit actions:

```swift
let resetable = SuperState(onEntry: [lock]) {
    when(.reset) | then(.locked)
}

define(.locked, adopts: resetable) {
    when(.coin) | then(.unlocked)
    when(.pass) | then(.alarming)
}

// equivalent to:

define(.locked, onEntry: [lock]) {
    when(.reset) | then(.locked)
    when(.coin)  | then(.unlocked)
    when(.pass)  | then(.alarming)
}
```

`SuperState` instances also inherit entry and exit actions from their superstates:

```swift
let s1 = SuperState(onEntry: [unlock])  { when(.coin) | then(.unlocked) }
let s2 = SuperState(onEntry: [alarmOn]) { when(.pass) | then(.alarming) }

let s3 = SuperState(adopts: s1, s2)

// s3 is equivalent to:

let s4 = SuperState(onEntry: [unlock, alarmOn]) { 
    when(.coin) | then(.unlocked)
    when(.pass) | then(.alarming)
}
```

#### Configuring Entry and Exit Actions Behaviour

In SMC, entry and exit actions are invoked even if the state does not change. In the example above, this would mean that the unlock entry action would be called on all transitions into the `Unlocked` state, *even if the FSM is already in the `Unlocked` state*. 

In contrast, **Swift FSM’s default behaviour is to invoke entry and exit actions _only if there is a state change_**. In the example above, this means that, in the `.unlocked` state, after a `.coin` event, `unlock` will *not* be called.

This policy is configurable: passing `.executeAlways` as the second argument to `FSM.init`, e.g. `FSM<State, Event>(initialState: .locked, actionsPolicy: .executeAlways'` will replicate SMC entry/exit action behaviour. By default argument is `.executeOnStateChangeOnly`.

### Syntax Order

All statements must be made in the form `define { when | then | actions }`. Any reordering will not compile.

See [Expanded Syntax][31] below for exceptions to this rule.

### Syntax Variations

Swift FSM allows you to alter the naming conventions in your syntax by using `typealiases`. Though `define`, `when`, and `then` are functions, there are matching structs with equivalent capitalised names contained in the `SwiftFSM.Syntax` namespace.

Here is one minimalistic example:

```swift
typealias d = Syntax.Define<State>
typealias w = Syntax.When<Event>
typealias t = Syntax.Then<State>

try fsm.buildTable {
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

It you wish to use this alternative syntax, it is strongly recommended that you *do not implement* `SyntaxBuilder`. Use the function syntax provided by `SyntaxBuilder`, *or* the struct syntax provided by the `Syntax` namespace. 

No harm will befall the FSM if you mix and match, but at the very least, from an autocomplete point of view, things will get messy. 

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

If the `if/else` block were evaluated by the FSM at transition time, this would indeed be a useful syntax. However what we are really doing inside these blocks is *compiling* our state transition table. The use of `if` and `else` in this manner is more akin to the conditional compilation statements `#if/#else` - based on a value defined at compile time, either one transition or the other will be selected and only that transition will be added to the table.

If you *do* have a use for this kind of conditional compilation, please open an issue and let me know. See the [Expanded Syntax][32] section for alternative syntax that enables the FSM to evaluate conditional statements at transition time.

### Runtime Errors

**Important** - most Swift FSM function calls and initialisers have an additional two arguments `file: String`  and `line: Int` that are populated with the default values `#file` and `#line`. This is similar to the system used by XCTest assertions, and allows Swift FSM to produce errors that can pinpoint the exact location of the problematic statement/s. 

There is no way to capture this information whilst hiding them from autocomplete - therefore, note that, unlike XCTest assertions, _there are no circumstances in which it could be useful or necessary to pass in your own values as arguments_.

#### Empty Blocks

All blocks must have at least one statement in them, otherwise an error will be thrown:

```swift
try fsm.buildTable { } //💥 error: empty table
try fsm.buildTable {
    define(.locked) { } // 💥 error: empty block
}
```

#### Duplicate Transitions

Swift FSM considers transitions to be duplicates if they share the same start state, event, and next state:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.coin) | then(.unlocked) | lock
    }
}

// 💥 error: duplicate transitions
```

#### Duplicate `buildTable` Calls

Any additional calls to `fsm.buildTable { }` will throw a `TableAlreadyBuiltError`, as the expected behaviour of such a call is undefined.

#### Logical Clashes

A logical clash occurs when two transitions share the same start state and event, but their next states differ:

```swift
try fsm.buildTable {
    define(.locked) {
        when(.coin) | then(.unlocked) | unlock
        when(.coin) | then(.locked)   | lock
    }
}

// 💥 error: logical clash
```

Thought the two transitions are clearly distinct from one another, from a logical point of view they cannot both be true - the `.coin` event must either lead to the `.unlocked` state or the `.locked` state. It cannot lead to both.

#### NSObject Error

`State` and `Event` instances are used to produce `Hashable` keys for the transition `Dictionary` during the call to `fsm.buildTable`. These keys are then recreated and reused each time `fsm.handleEvent` is called. The entire system therefore depends on its ability to hash both `State` and `Event` objects *by their value* - multiple instances with the same values but different identities need to equate. 

This is not an issue for most Swift types, as `Hashable` conformance will have to be declared explicitly. `NSObject` however already conforms to `Hashable`, and is hashed *by instance identity*, rather than by value. Therefore, an error will be thrown if Swift FSM detects any trace of `NSObject` anywhere near your `State` or `Event` types. 

This is very much an edge case and it is extremely unlikely that you will ever fall foul of this rule, unless you do so intentionally. Nonetheless, the check is quite exhaustive - If you would like to see how this check works, see the dependency [Reflective Equality][33].

### Performance

Swift FSM uses a Dictionary to store the state transition table, and each time `handleEvent()` is called, it performs a single O(1) operation to find the correct transition. Though O(1) is ideal from a performance point of view, an O(1) lookup is still significantly slower than a nested switch case statement, and Swift FSM is approximately 2-3x slower per transition.

## Expanded Syntax

Swift FSM matches most of the syntax of SMC, however it also introduces some new possibilities of its own. None of this additional syntax is required, and is provided for convenience.

### Example

Let’s imagine an extension to our turnstile rules, whereby under some circumstances, we might want to strongly enforce the ‘everyone pays’ rule by entering the alarming state if a `.pass` is detected when still in the `.locked` state, yet in others, perhaps at rush hour for example, we might want to be more permissive in order to avoid disruption to other passengers.

We could implement a check somewhere else in the system, perhaps inside the implementation of the `alarmOn` function to decide what the appropriate behaviour should be depending on the time of day.

```swift
try fsm.buildTable {
    ...
    define(.locked) {
        when(.pass) | then(.alarming) | handleAlarm
    }
    ...
}

// some other file somewhere...

enum Enforcement: Predicate { case weak, strong }

let enforcement = Enforcement.weak

func handleAlarm() {
    switch enforcement {
    case .weak: smile()
    case .strong: defconOne()
    }
}
```

But this comes with a problem - we now have some aspects of our state transitions declared inside the transition table, and other aspects declared elsewhere. It also requires us to transition to the `.alarming` state, regardless of the `Enforcement` policy. But what if different policies implied different transitions altogether?

An alternative might be to introduce an extra event to differentiate between the two policies:

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

This has the advantage not only of allowing us to call different functions, but also of transitioning to a different state, dependent on the enforcement policy. 

The down side is that every transition that originally responded to the `.pass` event will now have to be written twice, once for each of the two new versions of this event, *even if they do the same thing in both cases*. In no time at all, the state transition table is going to become unmanageably long, and littered with duplication. 

Following this path allows us to keep all of our logic inside the transition table, but it violates the Open/Closed principle - in order to extend the table’s behaviour, we would have to modify all of its existing parts.

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

The define statement …
> ```swift
> define(.locked) {
>     matching(Enforcement.weak)   | when(.pass) | then(.locked)   | smile
>     matching(Enforcement.strong) | when(.pass) | then(.alarming) | defconOne
>                 
>     when(.coin) | then(.unlocked) | unlock
> }
> ```
… now reads as follows:

Given that we are in the locked state:
- If `Enforcement` is `.weak`, when we get a `.pass`, transition to `.locked` and `smile`
- If `Enforcement` is `.strong`, when we get a `.pass`, transition to `.alarming` and `defconOne`
- **Regardless** of `Enforcement`, when we get a `.coin`, transition to `.unlocked` and `unlock`

This allows the extra `Enforcement` logic to be expressed directly within the FSM table without violating the Open/Closed principle. Only those statements that care about the `Enforcement` policy need know it exists, and all other preexisting statements continue to work as they always did.

### ExpandedSyntaxBuilder and Predicate

`ExpandedSyntaxBuilder` inherits from `SyntaxBuilder`, providing all the SMC-equivalent syntax, whilst adding the new `matching` statements for working with predicates. For the `Struct` based variant syntax, the equivalent namespace is `SwiftFSM.Syntax.Expanded`.  

`Predicate` requires the conformer to be `Hashable` and `CaseIterable`. `CaseIterable` conformance allows the FSM to calculate all the possible cases of the `Predicate`, such that, if none is specified, it can match that statement to *any* of its cases. It is possible to use any type you wish, as long as your conformance to `Hashable` and `CaseIterable` makes logical sense. In practice however, this requirement is likely to limit `Predicates` to `Enums` without associated types, as these can be automatically conformed to `CaseIterable`. 

### Implicit Matching Statements

```swift
when(.coin) | then(.unlocked)
```

In the line above, no `Predicate` is specified, and its full meaning is therefore inferred from its context. The scope for predicate inference is the sum of the builder blocks for all `SuperState` and `define` calls inside `fsm.buildTable { }`.  

In this case, the type `Enforcement` appears in a `matching` statement elsewhere in the table, and Swift FSM will therefore to infer the absent `matching` statement as follows:

```swift
when(.coin) | then(.unlocked)

// is inferred to mean:

matching(Enforcement.weak)   | when(.coin) | then(.unlocked)
matching(Enforcement.strong) | when(.coin) | then(.unlocked)
```

Statements in Swift FSM are are therefore `Predicate` agnostic by default, and will match any given `Predicate`. In this way, `matching` statements are optional specifiers that *constrain* the transition to one or more specific `Predicate` cases. If no `Predicate` is specified, the statement will match all cases.

### Multiple Predicates

Swift FSM does not limit the number of `Predicate` types that can be used in one table. The following (contrived and rather silly) expansion of the original `Predicate` example is equally valid:

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

The same inference rules continue to apply:

```swift
when(.coin) | then(.unlocked)

// now in a two predicate context, equivalent to:

matching(Enforcement.weak)   | when(.coin) | then(.unlocked)
matching(Enforcement.strong) | when(.coin) | then(.unlocked)
matching(Reward.positive)    | when(.coin) | then(.unlocked)
matching(Reward.negative)    | when(.coin) | then(.unlocked)
```

### Implicit Clashes

#### Between Predicates

```swift
define(.locked) {
    matching(Enforcement.weak) | when(.coin) | then(.unlocked)
    matching(Reward.negative)  | when(.coin) | then(.locked)
}

// 💥 error: implicit clash
```

On the surface of it, the two transitions above appear to be different from one another. However if we remember the inference rules, we will see that they actually conflict:

```swift
define(.locked) {
    matching(Enforcement.weak)   | when(.coin) | then(.unlocked) // clash 1
// also inferred as:
    matching(Reward.positive)    | when(.coin) | then(.unlocked)
    matching(Reward.negative)    | when(.coin) | then(.unlocked) // clash 2	

    matching(Reward.negative)    | when(.coin) | then(.locked)   // clash 2
// also inferred as:
    matching(Enforcement.weak)   | when(.coin) | then(.locked)   // clash 1
    matching(Enforcement.strong) | when(.coin) | then(.locked)
```

We can break the deadlock by adding some disambiguation:

```swift
define(.locked) {
    matching(Enforcement.weak, and: Reward.positive) | when(.coin) | then(.unlocked)
    matching(Reward.negative)                        | when(.coin) | then(.locked)
}

// ✅ inferred as:

define(.locked) {
    matching(Enforcement.weak,   and: Reward.positive) | when(.coin) | then(.unlocked)

    matching(Enforcement.weak,   and: Reward.negative) | when(.coin) | then(.locked)
    matching(Enforcement.strong, and: Reward.positive) | when(.coin) | then(.locked)
    matching(Enforcement.strong, and: Reward.nevagive) | when(.coin) | then(.locked)
}
```

In this case, Swift FSM breaks the tie by deferring to the more deeply specified statement (in this case, the first statement, which specifies two predicates, versus the second statement’s single predicate). This is a general inference rule - if two statements potentially clash, they will throw if they both specify the same number of predicates (Swift FSM cannot break the tie), otherwise the more specified option will always be preferred.

#### Within Predicates

Following the inference logic, connecting different types using the word ‘or’ is also not allowed:

```swift
define(.locked) {
    matching(Enforcement.weak, or: Reward.negative) | when(.coin) | then(.unlocked)
}

// ⛔️ error: does not compile, because it implies:

define(.locked) {
    matching(Enforcement.weak) | when(.coin) | then(.unlocked) // ⛔️ clash
    matching(Reward.negative)  | when(.coin) | then(.unlocked) // ⛔️ clash
}
```

If we were to call `handleEvent(.coin, predicates: Enforcement.weak, Reward.negative)` with such a table, there would be no reasonable way to decide which transition to perform. Unlike between-predicates implicit clashes, within-predicates clashes can be eliminated through the type system, and therefore cannot occur at runtime.

### Deduplication

In the following case, `when(.pass)` is duplicated:

```swift
matching(Enforcement.weak)   | when(.pass) | then(.locked)
matching(Enforcement.strong) | when(.pass) | then(.alarming)
```

 We can remove duplication as follows:

```swift
when(.pass) {
    matching(Enforcement.weak)   | then(.locked)
    matching(Enforcement.strong) | then(.alarming)
}
```

Here we have created a `when` context block. Anything in that context will assume that the event in question is `.pass`. 

The full example would now be:

```swift
try fsm.buildTable {
    ...
    define(.locked) {
        when(.pass) {
            matching(Enforcement.weak)   | then(.locked)
            matching(Enforcement.strong) | then(.alarming)
        }
                
        when(.coin) | then(.unlocked)
    }
    ...
}
```

`then` and `matching` support deduplication in a similar way:

```swift
try fsm.buildTable {
    ...
    define(.locked) {
        then(.unlocked) {
            when(.pass) {
                matching(Enforcement.weak)   | doSomething
                matching(Enforcement.strong) | doSomethingElse
            }
        }
    }
    ...
}
```

```swift
try fsm.buildTable {
    ...
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
    ...
}
```

The keyword `actions` is available for deduplicating function calls:

```swift
try fsm.buildTable {
    ...
    define(.locked) {
        actions(someCommonFunction) {
            when(.coin) | then(.unlocked)
            when(.pass) | then(.alarming)
        }
    }
    ...
}
```

### Chained Blocks

Deduplication has introduced us to four blocks:

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

They can be divided into two groups - blocks that can be logically chained (or AND-ed) together, and blocks that cannot.

#### Discrete Blocks - `when` and `then`

Each transition can only respond to a single event, and transition to a single state. Therefore multiple `when { }` and `then { }` blocks cannot be AND-ed together.

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

Additionally, there is a specific combination of  `when` and `then` that does not compile:

```swift
define(.locked) {
    when(.coin) {
        then(.unlocked) | action // ⛔️ does not compile
        then(.locked)   | action // ⛔️ does not compile
    }
}
```

Logically, there is no situation where, in response to a single event (in this case, `.coin`), there could then be a transition to more than one state, unless a different `Predicate` is stated for each. 

Therefore the following is allowed:

```swift
define(.locked) {
    when(.coin) {
        matching(Enforcement.weak)   | then(.unlocked) | action // ✅
        matching(Enforcement.strong) | then(.locked)   | otherAction // ✅
    }
}
```

Note that by doing this, it is quite easy to form a duplicate that cannot be checked at compile time. For example:

```swift
define(.locked) {
    when(.coin) {
        matching(Enforcement.weak) | then(.unlocked) | action // ✅
        matching(Enforcement.weak) | then(.locked)   | otherAction // ✅
    }
}

// 💥 error: logical clash
```

#### Chainable Blocks - `matching` and `actions`

There is no logical restriction on the number of predicates or actions per transition, and therefore both can be built up in a chain as follows:

```swift
define(.locked) {
    matching(Enforcement.weak) {
        matching(Reward.positive) { } // ✅
        matching(Reward.positive) | ... // ✅
    }

    actions(doSomething) {
        actions(doSomethingElse) { } // ✅
        ... | doSomethingElse // ✅
    }      
}
```

Nested `actions` blocks sum the actions and perform all of them. In the above example, anything declared inside `actions(doSomethingElse) { }` will call both `doSomethingElse()` and `doSomething()`.

Nested `matching` blocks are AND-ed together. In the above example, anything declared inside `matching(Reward.positive) { }` will match both `Enforcement.weak` AND `Reward.positive`. 

#### Mixing blocks and pipes

Pipes can and must be used inside blocks, whereas blocks cannot be opened after pipes

```swift
define(.locked) {
    when(.coin) | then(.unlocked) { } // ⛔️ does not compile
    when(.coin) | then(.unlocked) | actions(doSomething) { } // ⛔️ does not compile
    matching(.something) | when(.coin) { } // ⛔️ does not compile
}
```

### Complex Predicates

```swift
enum A: Predicate { case x, y, z }
enum B: Predicate { case x, y, z }
enum C: Predicate { case x, y, z }

matching(A.x)... // if A.x
matching(A.x, or: A.y)... // if A.x OR A.y
matching(A.x, or: A.y, A.z)... // if A.x OR A.y OR A.z
matching(A.x, or: B.x)... // ⛔️ does not compile: OR types must be the same

matching(A.x, and: B.x)... // if A.x AND B.x
matching(A.x, and: A.y)... // 💥 error: cannot match A.x AND A.y simultaneously
matching(A.x, and: B.x, C.x)... // if A.x AND B.x AND C.x

matching(A.x, or: A.y, A.z, and: B.x, C.x)... // if (A.x OR A.y OR A.z) AND B.x AND C.x

fsm.handleEvent(.coin, predicates: A.x, B.x, C.x)
```

All of these `matching` statements can be used both with `|` syntax, and with deduplicating `{ }` syntax, as demonstrated with previous `matching` statements.

They should be reasonably self-explanatory, perhaps with the exception of why `matching(A.x, and: A.y)` is an error. 

In Swift FSM, the word ‘and’ means that we expect both predicates to be present *at the same time*. Each predicate type can only have one value at the time it is passed to `handleEvent()`, therefore asking it to match multiple values of the same `Predicate` type simultaneously has no meaning. The rules of the system are that, if `A.x` is current, `A.y` cannot also be current.

For clarity, it can be useful to think of `matching(A.x, and: A.y)` as meaning `matching(A.x, andSimultaneously: A.y)`. In terms of a `when` statement to which it is analogous, it would be as meaningless as saying `when(.coin, and: .pass)` - the event is either `.coin` or `.pass`, it cannot be both.

The word ‘or’ is more permissive - `matching(A.x, or: A.y)` can be thought of as `matching(anyOneOf: A.x, A.y)`. For an explanation of why `matching(A.x, or: B.x)` is not allowed, see [Implicit Clashes][34].

**Important** - remember that nested `matching` statements are combined by AND-ing them together, which makes it possible inadvertently to create a conflict.

```swift
define(.locked) {
    matching(A.x) {
        matching(A.y) {
            // 💥 error: cannot match A.x AND A.y simultaneously 
        }
    }
}
```

This AND-ing behaviour also applies to OR statements: 

```swift
define(.locked) {
    matching(A.x, or: A.y) {
        matching(A.z) {
            // 💥 error: cannot match A.x AND A.y simultaneously 
            // 💥 error: cannot match A.x AND A.z simultaneously
            // 💥 error: cannot match A.y AND A.z simultaneously  
        }
    }
}
```

Nested OR statements that do not conflict are AND-ed as follows:

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

### Condition Statements

Using Predicates with `matching` syntax is a versatile solution, however in some cases it may bring more complexity than is necessary to solve a given problem.

If you need to make a specific transition conditional at runtime, then the `condition` statement may suffice. Some FSM implementations call this a `guard` statement, however the name `condition` was chosen here as `guard` is a reserved word in Swift.

```swift
define(.locked) {
    condition(complicatedDecisionTree) | when(.pass) | then(.locked) | lock 
}
```

Here, `complicatedDecisionTree()` is a function that returns a `Bool`. If it is `true`, the transition is executed, and if it is not, nothing is executed.

The keyword `condition` is syntactically interchangeable with `matching` - it works with pipe and block syntax, and is chainable (conditions are AND-ed together).

`matching` and `condition` blocks can also be combined freely:

```swift
define(.locked) {
    condition({ reward == .positive }) {
        matching(Enforcement.weak)   | then(.unlocked) | action
        matching(Enforcement.strong) | then(.locked)   | otherAction
    }
}
```

The advantage of `condition` over `matching` (assuming that either will suffice) is that the overhead of using`condition` is significantly lower (see [Predicate Performance][35] for details). You can express conditional logic without needing to create new `Predicate` types and pass them to `handleEvent`.

The disadvantage of `condition` versus `matching` is that it is more limited in the kinds of logic it can express:

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

The FSM has no way to distinguish between different `condition` statements - it cannot ‘see into’ the `() -> Bool` blocks, and must therefore evaluate the statements as if they did not exist. 

What therefore remains is two statements `define(.locked) { when(.coin) | ... }` that both transition to different states - the FSM has no way to understand which one to call, and must therefore `throw`.

### Runtime Errors

In order to preserve performance, `fsm.handleEvent(event:predicates:)` performs no error handling. Therefore, passing in `Predicate` instances that do not appear anywhere in the transition table will not error. Nonetheless, the FSM will be unable to perform any transitions, as it will not contain any statements that match the given, unexpected `Predicate` instance. It is the caller’s responsibility to ensure that the predicates passed to `handleEvent` and the predicates used in the transition table are of the same type and number.

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

See [Implicit Clashes][36]

### Predicate Performance

Adding predicates has no effect on the performance of `handleEvent()`. To maintain this performance, it does significant work ahead of time when creating the transition table, filling in missing transitions for all implied `Predicate` combinations.

The performance of `fsm.buildTransitions { }` is dominated by this, assuming any predicates are used at all. Because all possible combinations of cases of all given predicates have to be calculated, performance is O(m^n) where m is the average number of cases per predicate, and n is number of`Predicate` types. Using three predicates with 10 cases each would therefore require 1,000 operations *for each transition in the table*.

#### Lazy FSM

For small tables, or tables with only a few total `Predicate` cases, this eager algorithm is likely to be the preferred option. For tables with a large number of transition statements, and/or a large number of `Predicate` cases, there is an alternative lazy solution that may be more performant overall. 

Replacing the `FSM` class with `LazyFSM` will do away with the look-ahead combinatorics algorithm described above. The result is smaller tables internally, and faster table compile time. The cost is at the call to `handleEvent()` where multiple lookup operations are needed to find the correct transition. These two systems therefore make opposite tradeoffs - the eager system does all of its work at table compile time, whereas the lazy system saves on compile time space and performance resources by doing its work at transition run time.

Performance of the `LazyFSM` implementation of `handleEvent()` increases from O(1) to O(n!), where `n` is the number of `Predicate` *types* used, regardless of the number of cases. Taking the same example as previously, using three predicates with 10 cases each, each call to `handleEvent()` would need to perform somewhere between a minimum of 1 operation, and a maximum of `3! + 1` or 7 operations. Using more than three `Predicate` types in this case is therefore not advisable.

## Troubleshooting

Though Swift FSM runtime errors contain verbose descriptions of the problem, including the exact files and lines where the original statements were made, nothing can be done to help with disambiguating compile time errors.

First, familiarity with how `@resultBuilder` works, and the kinds of compile time errors it tends to generate will be very helpful in understanding the errors you may encounter. Almost all Swift FSM-specific compile time errors will be produced by one of two sources - unrecognised arguments to the aforementioned `@resultBuilder`, and unrecognised arguments to the `|` operator overloaded by Swift FSM.

To help, here is a brief list of common errors you are likely to encounter if you try to build something that Swift FSM specifically disallows at compile time:

### Builder Issues

\- 

### Pipe Issues

\- 




[1]:	https://github.com/unclebob/CC_SMC
[2]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#resultBuilder
[3]:	https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/
[4]:	https://github.com/apple/swift-evolution/blob/main/proposals/0253-callable.md
[5]:	#requirements
[6]:	#basic-syntax
[7]:	#optional-arguments
[8]:	#super-states
[9]:	#entry-and-exit-actions
[10]:	#syntax-order
[11]:	#syntax-variations
[12]:	#syntactic-sugar
[13]:	#runtime-errors
[14]:	#performance
[15]:	#expanded-syntax
[16]:	#example
[17]:	#expandedsyntaxbuilder-and-predicate
[18]:	#implicit-matching-statements
[19]:	#multiple-predicates
[20]:	#implicit-clashes
[21]:	#deduplication
[22]:	#chained-blocks
[23]:	#complex-predicates
[24]:	#condition-statements
[25]:	#error-handling
[26]:	#predicate-performance
[27]:	#troubleshooting
[28]:	https://github.com/apple/swift-algorithms
[29]:	#nsobject-error
[30]:	https://github.com/drseg/reflective-equality
[31]:	#expanded-syntax
[32]:	#expanded-syntax
[33]:	https://github.com/drseg/reflective-equality
[34]:	#implicit-clashes
[35]:	#predicate-performance
[36]:	#implicit-clashes