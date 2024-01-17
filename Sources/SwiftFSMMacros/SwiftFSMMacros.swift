@freestanding(declaration, names: arbitrary)
public macro letEvent(_ named: String) =
#externalMacro(module: "SwiftFSMMacrosEvent",
               type: "StaticLetEventMacro")

@freestanding(declaration, names: arbitrary)
public macro letEvents(_ named: String...) =
#externalMacro(module: "SwiftFSMMacrosEvent",
               type: "StaticLetEventMacro")

@freestanding(declaration, names: arbitrary)
public macro funcEvents(_ named: String...) =
#externalMacro(module: "SwiftFSMMacrosEvent",
               type: "StaticFuncEventMacro")

@freestanding(declaration, names: arbitrary)
public macro funcEventsWithValue(_ named: String...) =
#externalMacro(module: "SwiftFSMMacrosEvent",
               type: "StaticFuncEventWithValueMacro")

@freestanding(declaration, names: arbitrary)
public macro letEventWithValue(_ named: String) =
#externalMacro(module: "SwiftFSMMacrosEvent",
               type: "StaticLetEventWithValueMacro")

@freestanding(declaration, names: arbitrary)
public macro letEventsWithValue(_ named: String...) =
#externalMacro(module: "SwiftFSMMacrosEvent",
               type: "StaticLetEventWithValueMacro")
