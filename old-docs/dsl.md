
Abbreviated description of only the bindings.

### Grammar

    binding ::= (NoBinding)
        | (Singleton lst) | (Constant lst int) | (Arbitrary lst)
    lst ::= Hint | Gap | Block
    int ::= integer literal

### Semantics

The *hints* are the list of hints from the partial state.
A *gap* is a (maximally) contiguous run of cells that are not *false* (either *true* or *empty*)
and a *block* is a (maximally) contiguous run of cells that are *true*.
*gaps(t)* is the sequence of pairs of start indices and lengths of all gaps,
and similarly with blocks.

    [(NoBinding)](t,i)          = true
    [(Singleton lst)](t,i)      = i = 0 ^ 1 = |bindinglist(t,lst)|
    [(Constant lst v)](t,i)     = i = v ^ 0 ≤ v < |bindinglist(t,lst)|
    [(Arbitrary lst)](t,i)      = 0 ≤ i < |bindinglist(t,lst)|

    bindinglist(t, Hint)        = i,hi for i in [0,k)
    bindinglist(t, Gap)         = gaps(t)
    bindinglist(t, Block)       = blocks(t)



