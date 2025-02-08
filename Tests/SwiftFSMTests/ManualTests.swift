#if(false)
@testable import SwiftFSM

class ManualTests: ExpandedSyntaxBuilder {
    typealias State = Int
    typealias Event = Int
    
    enum A: Predicate { case x }
    enum B: Predicate { case x }
    
    func function() { }
    
    func orTypesMustBeTheSame() {
        _ = matching(A.x, or: B.x)
    }
    
    func cannotChainWhens1() {
        define(1) {
            when(1) {
                when(1) { }
            }
        }
    }
    
    func cannotChainWhens2() {
        define(1) {
            when(1) {
                when(1) | then()
            }
        }
    }
    
    func cannotChainWhens3() {
        define(1) {
            when(1) {
                matching(A.x) | when(1) | function
            }
        }
    }
    
    func cannotChainWhens4() {
        define(1) {
            when(1) {
                matching(A.x) {
                    when(1) { }
                }
            }
        }
    }
    
    func cannotChainWhens5() {
        define(1) {
            when(1) {
                matching(A.x) {
                    when(1) | then()
                }
            }
        }
    }
    
    func cannotChainThens1() {
        define(1) {
            then(1) {
                then(1) { }
            }
        }
    }
    
    func cannotChainThens2() {
        define(1) {
            then(1) {
                then(1) | then()
            }
        }
    }
    
    func cannotChainThens3() {
        define(1) {
            then(1) {
                matching(A.x) | then(1) | function
            }
        }
    }
    
    func cannotChainThens4() {
        define(1) {
            then(1) {
                matching(A.x) {
                    then(1) { }
                }
            }
        }
    }
    
    func cannotChainThens5() {
        define(1) {
            then(1) {
                matching(A.x) {
                    then(1) | then()
                }
            }
        }
    }
    
    func cannotWhenMultipleThen() {
        define(1) {
            when(2) {
                then(.unlocked)
                then(1)
                then(.unlocked) | function
                then(1)         | function
            }
        }
    }
    
    func invalidBlocksAfterPipes1() {
        define(1) {
            when(1) | then(1) { }
        }
    }
    
    func invalidBlocksAfterPipes2() {
        define(1) {
            when(1) | then(1) | actions(function) { }
        }
    }
    
    func invalidBlocksAfterPipes3() {
        define(1) {
            matching(A.x) | when(1) { }
        }
    }
    
    #warning("this seems to compile when it shouldn't")
    func noControlLogicInBuilders() {
        define(1) {
            if(false) {
                when(2) | then()
            } else {
                when(2) | then()
            }
        }
    }
}

#endif
