# Swift FSM
### Friendly Finite State Machine Syntax for Swift, iOS and macOS

Inspired by [Uncle Bob's SMC][1] syntax, SwiftFSM is a pure Swift syntax for declaring and operating a Finite State Machine (FSM). Unlike Uncle Bob’s SMC, the FSM itself is declared inside your Swift code, rather than as a separate text file, and compiles and runs directly alongside all your other project code.

This guide is reasonably complete, but does presume some familiarity with FSMs and specifically the SMC syntax linked above.

## Requirements:

SwiftFSM is a Swift package, importable through the Swift Package Manager, and requires macOS 12.6 and/or iOS 15.6 or later, alongside Swift 5.6 or later.

## Example:

Borrowing from SMC, we have an example of a simple subway turnstile system. This turnstile currently has two possible states: `Locked`, and `Unlocked`, alongside two possible events: `Coin`, and `Pass`.

The logic is as follows (from Uncle Bob, emphasis added): 

> - *Given* we are in the *Locked* state, *when* we get a *Coin* event, *then* we transition to the *Unlocked* state and *invoke* the *unlock* action.
> - *Given* we are in the *Locked* state, *when* we get a *Pass* event, *then* we stay in the *Locked* state and *invoke* the *alarm* action.
> - *Given* we are in the *Unlocked* state, *when* we get a *Coin* event, *then* we stay in the *Unlocked* state and *invoke* the *thankyou* action.
> - *GIven* we are in the *Unlocked* state, *when* we get a *Pass* event, *then* we transition to the *Locked* state and *invoke* the *lock* action.

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
import SwiftFSM

class MyClass: TransitionBuilder {
    enum State { case locked, unlocked }
    enum Event { case coin, pass }

    let fsm = FSM<State, Event>(initialState: .locked)

    func myMethod() {
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
        when(.reset) | then(.locked) | { alarmOff() ; lock() }
    }
}
```

`then()` with no argument means ‘no change’, and the FSM will remain in the current state.  The actions argument is also optional - if a transition performs no actions, it can be omitted.

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

### Syntax Order

All statements must be made in the form `define { when | then | actions }`. Any reordering will not compile.

See [Expanded Syntax][2] below for exceptions to this rule.

### Syntax Variations

SwiftFSM allows you to alter the naming conventions in your syntax by using `typealiases`. Though `define`, `when`, and `then` are functions, there are matching structs with equivalent capitalised names contained in the `SwiftFSM.Syntax` namespace.

Here is one minimalistic example:

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

It you wish to use this alternative syntax, it is strongly recommended that you *do not implement* `TransitionBuilder`. Use the function syntax provided by `TransitionBuilder`, *or* the struct syntax provided by the `Syntax` namespace. 

No harm will befall the FSM if you mix and match, but at the very least, from an autocomplete point of view, things will get messy. 

### Performance

SwiftFSM uses a Dictionary to store the state transition table, and each time `handleEvent()` is called, it performs a single O(1) operation to find the correct transition. Though O(1) is ideal from a performance point of view, any lookup table is significantly slower than a nested switch case statement, and SwiftFSM is approximately 2-3x slower per transition.

## Expanded Syntax

SwiftFSM matches the syntax possibilities offered by SMC, however it also introduces some new possibilities of its own. None of this additional syntax is required, and is provided for convenience.

### Rationale

Though the turnstile is a pleasing example, it is also conveniently simple. Given that all computer programs are in essence FSMs, there is no limit to the degree of complexity an FSM table might reach. At some point on the complexity scale, SMC and SwiftFSM basic syntax would become so lengthy as to be unusable.

### Example

Let’s imagine an extension to our turnstile rules, whereby under some circumstances, we might want to strongly enforce the ‘everyone pays’ rule by entering the alarming state if a `.pass` is detected when still in the `.locked` state, yet in others, perhaps at rush hour for example, this behaviour might be too disruptive to other passengers.

We could implement a check somewhere else in the system, perhaps inside the `alarmOn` function to decide what the appropriate behaviour should be.

But this comes with a problem - we now have some aspects of our state transitions declared inside the transition table, and other aspects declared elsewhere. Though this problem is inevitable in software, SwiftFSM provides a mechanism to add this additional decision tree into the FSM table itself.

```swift
enum Enforcement: Predicate { case weak, strong }

try fsm.buildTable {
    ...
    define(.locked) {
        matching(Enforcement.weak)   | when(.pass) | then(.locked)
        matching(Enforcement.strong) | when(.pass) | then(.alarming)
                
        when(.coin) | then(.unlocked)
    }
    ...
}

fsm.handleEvent(.pass, predicates: Enforcement.weak)
```

Here we have introduced a new keyword `matching`, and a new protocol `Predicate`. The define statement with its three sentences now reads as follows:

- Given that we are in the locked state:
	- If the `Enforcement` strategy is `.weak`, when we get a `.pass` event, transition to the `.locked` state
	- If the `Enforcement` strategy is `.strong`, when we get a `.pass` event, transition to the `.alarming` state
	- **Regardless** of `Enforcement` strategy, when we get a `.coin` event, transition to the `.unlocked` state

This allows the extra `Enforcement`logic to be expressed directly within the FSM table

### Detailed Description

`Predicate` requires the conformer to be `Hashable` and `CaseIterable`. The `CaseIterable` conformance allows the FSM to calculate all the possible cases of the `Predicate`, such that, if none is specified, it can match that statement to *any* of its cases. It is possible to use any type you wish, as long as your conformance to `CaseIterable` makes logical sense. In practice however, this requirement is likely to limit `Predicates` to `Enums` without associated types, as these can be automatically conformed to `CaseIterable`. 

#### Implicit `matching` statements:

Take this example from the example above:

```swift
...
when(.coin) | then(.unlocked)
...
```

As no `Predicate` is specified here, its meaning is inferred by SwiftFSM depending on its context. In this case, the type `Enforcement` appears in a `matching` statement elsewhere in the table, and SwiftFSM will therefore infer it to be equivalent to:

```swift
...
matching(Enforcement.weak)   | when(.coin) | then(.unlocked)
matching(Enforcement.strong) | when(.coin) | then(.unlocked)
...
```

In other words, it is `Predicate` agnostic, and will match any given `Predicate`. In this way, `matching` statements are optional specifiers that *constrain* the transition to one or more specific `Predicate` cases. If no `Predicate` is specified, the statement will match all cases.

#### Multiple Predicates

SwiftFSM does not limit the number of `Predicate` types that can be used in one table. The following (contrived and rather silly) expansion of the original `Predicate` example is equally valid:

```swift
enum Enforcement: Predicate { case weak, strong }
enum Reward: Predicate { case positive, negative }

try fsm.buildTable {
    ...
    define(.locked) {
        matching(Enforcement.weak)   | when(.pass) | then(.locked)   | lock
        matching(Enforcement.strong) | when(.pass) | then(.alarming) | alarmOn
                
        when(.coin) | then(.unlocked)
    }

    define(.unlocked) {
        matching(Reward.positive) | when(.coin) | then(.unlocked) | thankyou
        matching(Reward.negative) | when(.coin) | then(.unlocked) | idiot
                
        when(.coin) | then(.unlocked)
    }
    ...
}

fsm.handleEvent(.pass, predicates: Enforcement.weak, Reward.positive)
```

The same inference rules also apply. The statement…

```swift
when(.coin) | then(.unlocked)
```

…in this new context with an additional `Predicate` will now be inferred as:

```swift
...
matching(Enforcement.weak)   | when(.coin) | then(.unlocked)
matching(Enforcement.strong) | when(.coin) | then(.unlocked)
matching(Reward.positive)    | when(.coin) | then(.unlocked)
matching(Reward.negative)    | when(.coin) | then(.unlocked)
...
```

#### Deduplication:

Take the following lines from the original example:

```swift
...
matching(Enforcement.weak)   | when(.pass) | then(.locked)
matching(Enforcement.strong) | when(.pass) | then(.alarming)
...
```

In this case, `when(.pass)` is duplicated. We can remove that duplication, replacing the above as follows:

```swift
when(.pass) {
    matching(Enforcement.weak)   | then(.locked)
    matching(Enforcement.strong) | then(.alarming)
}
```

Here we have created a `when` context block. Anything inside that context will assume that the event in question is `.pass`. 

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

`then` and `matching` also support deduplication in a similar way:

`then` deduplication:

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

`matching` deduplication:

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

`actions` is also available for deduplicating function calls:

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

#### Chained Blocks

The deduplication section introduced four blocks:

```swift
matching(predicate) { 
    // everything inside this block matches 'predicate'
}

when(event) { 
    // everything inside this block responds to the event 'event'
}

then(state) { 
    // everything inside this block transitions to the state 'state'
}

actions(functionCalls) { 
   // everything inside this block calls 'functionCalls'
}
```

They can be divided into two groups - blocks that can be chained together, and blocks that cannot.

##### Discrete Blocks - `when` and `then`

Each transition can only respond to a specific event, and then transition to a specific state. Therefore `when {}` and `then {}` blocks cannot be chained.

```swift
define(.locked) {
    when(.coin) {
        when(.pass) { } // error: does not compile
        when(.pass) | ... // error: does not compile

        matching(.something) | when(.pass) | ... // error: does not compile

        matching(.something) { 
            when(.pass) | ... // error: does not compile
        }

        matching(.something) { 
            when(.pass) { } // error: does not compile
        }
    }

    then(.unlocked) {
        then(.locked) { } // error: does not compile
        then(.locked) | ... // error: does not compile

        matching(.something) | then(.locked) | ... // error: does not compile

        matching(.something) { 
            then(.locked) | ... // error: does not compile
        }

        matching(.something) { 
            then(.locked) { } // error: does not compile 
        }
    }      
}

```

Additionally, there is a specific combination of  `when` and `then` that does not compile:

```swift
define(.locked) {
    when(.coin) {
        then(.unlocked) | action // error: does not compile
        then(.locked)   | action // error: does not compile
    }
}
```

Logically, there is no situation where in response to an event (in this case, `.coin`), there could be a transition to more than one state unless an extra `Predicate` is stated. Therefore the following is allowed:

```swift
define(.locked) {
    when(.coin) {
        matching(Enforcement.weak)   | then(.unlocked) | action // ok
        matching(Enforcement.strong) | then(.locked)   | otherAction // ok
    }
}
```

Note that it is easy to form a duplicate that cannot be checked at compile time. For example:

```swift
define(.locked) {
    when(.coin) {
        matching(Enforcement.weak) | then(.unlocked) | action // ok
        matching(Enforcement.weak) | then(.locked)   | otherAction // ok
    }
}

// runtime error: logical clash
```

See the errors section for more information

##### Chainable Blocks - `matching` and `actions`

There are no restrictions on the number of predicates or actions per transition, therefore both can be chained as follows:

```swift
define(.locked) {
    matching(Enforcement.weak) {
        matching(Reward.positive) { } // ok
        matching(Reward.positive) | ... // ok
    }

    actions(doSomething) {
        actions(doSomethingElse) { } // ok
        ... | doSomethingElse // ok
    }      
}
```

Nested `actions` blocks simply sum the actions and perform all of them. In the above example, anything declared inside `actions(doSomethingElse) { }` will call both `doSomethingElse()` and `doSomething()`.

Nested `matching` blocks are AND-ed together. In the above example, anything declared inside `matching(Reward.positive) { }` will match both `Enforcement.weak` AND `Reward.positive`. 

#### Complex Predicates

```swift
enum A: Predicate { case x, y, z }
enum B: Predicate { case x, y, z }
enum C: Predicate { case x, y, z }

matching(A.x)... // if A.x
matching(A.x, or: A.y)... // if A.x OR A.y
matching(A.x, or: A.y, A.z)... // if A.x OR A.y OR A.z

matching(A.x, and: B.x)... // if A.x AND B.x
matching(A.x, and: A.y)... // throws Error: AND-ed values must be different types
matching(A.x, and: B.x, C.x)... // if A.x AND B.x AND C.x

matching(A.x, or: A.y, A.z, and: B.x, C.x)... // if (A.x OR A.y OR A.z) AND B.x AND C.x

fsm.handleEvent(.coin, predicates: A.x, B.x, C.x)
```

All of these `matching` statements can be used both with `|` syntax, and with deduplicating `{ }` syntax, as demonstrated with previous `matching` statements.

They should be reasonably self-explanatory, perhaps with the exception of why `matching(A.x, and: A.y) // throws error`. In SwiftFSM, the word ‘and’ means that we expect both predicates will be present *at the same time*. Each predicate type can only have one value at the time it is passed to `handleEvent()`, therefore asking it to match multiple values of the same `Predicate` simultaneously has no meaning. The rules of the system are that, if `A.x` is current, `A.y` cannot also be current.

For clarity, it can be useful to think of `matching(A.x, and: A.y)` as meaning `matching(A.x, andSimultaneously: A.y)`. In terms of a `when` statement to which it is analogous, it would be as meaningless as saying `when(.coin, and: .pass)` - the event is either `.coin` or `.pass`, it cannot be both.

The word ‘or’ is more permissive - `matching(A.x, or: A.y)` can be thought of as `matching(anyOneOf: A.x, A.y)`.

#### Predicate Performance

Adding predicates has no effect on the performance of `handleEvent()`. To maintain this performance, it does significant work ahead of time when creating the transition table, filling in missing transitions for all implied `Predicate` combinations.

The performance of `fsm.buildTransitions { }` is dominated by this, assuming any predicates are used at all. Because all possible combinations of cases of all given predicates have to be calculated, performance is O(m\*n) where m is the number of`Predicate` types, and n is the average number cases per `Predicate`.

Using three predicates, each with 10 cases each, would therefore require 1,000 operations to calculate all possible combinations.

#### Error Handling

In order to preserve performance, `fsm.handleEvent(event:predicates:)` performs no error handling. Therefore, passing in `Predicate` instances that do not appear anywhere in the transition table will not error. Nonetheless, the FSM will be unable to perform any transitions, as it will not contain any statements that match the given, unexpected `Predicate` instance.

[1]:	https://github.com/unclebob/CC_SMC
[2]:	#expanded-syntax "Expanded Syntax"