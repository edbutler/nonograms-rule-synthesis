
# Nonograms!

Problem Description, Formalisms, etc.

## Formalism

### Rules

We are given a problem domain, in this case the puzzle Nonograms.
Problem domains are defined by:

- A set of possible *states*.
- A *transition function* describing valid moves from state to state.
- A *goal predicate* on states that describe when a problem is solved.

Problems are given by a starting state.
These are assumed to be formally given.
Sometimes the transition function is concisely describing (e.g., algebra, with a set of axioms).
Sometimes, as is the case with nonograms, it's a bit more implicit,
basically saying that moves are valid if they don't break solvability.
Our states in nonograms are a partially filled out grid (each cell can be true/on, false/off, or unknown)
and a sequence of positive integer hints for every row and column of the grid.
Valid transitions from *S* to *T* are those in which:

- *S* and *T* have equal hint sequences
- For every true/false (not unknown) cell in *S*, that cell has the same value in *T*
  (unknown cells may be different)
- *T* is solvable (there exists a true/false assignment to all unknown cells in *T* that satisfy the rules of nonograms).

A *rule* is a subset of this transition function.
In the case of domains like algebra, a rule is actually a composition of subsets of the transition function,
but, in the case of nonograms, the transition function implicitly covers everything so we don't need that machinery.
These rules are elements of procedural knowledge that can be applied to solve a problem.

With even this simple notion of rules, we can already define a basic metric for the *generality* of a rule:
a rule's generality is the size of its domain (for which it has a non-bottom value).
We will later use more notions of generality that are a weighted sum rather than a simple count.

We are also interested in quantifying a proxy for the squishy notion of "easy to use."
For example, if finding rules for educational use, the cognitive load required to apply a rule is critical to understand.
We won't pretend to measure the true cognitive load of rules, but instead use proxies to estimate this.

In order to do this, we focus on rules expressible in a given Domain-Specific Programming Language (DSL).
This language is assumed to be designed to capture elements of how someone could conceivably solve problems.
For example, in nonograms, there would be elements for reading the hints, reading cells, or filling in certain cells.
We can define a monotonic function mapping programs in this DSL to the reals measuring the size of a program.
We will use this as an (unvalidated) proxy for cognitive load, which we call the *cost* of a rule.

To summarize, we have two notions for what a rule is.
In one lens, it is a program in some language which is designed to be human-readable and
(roughly) correspond to procedural instructions for a human to apply such a rule.
We can measure "good" rules in this lens as those with concise, simple programs.
The other lens for rules is as subsets of the universal transition function.
In this lens a "good" rule is that which has a large domain, the best being the transition function itself.

### Line Contexts

We could, in theory, consider rules that apply to the entire board at once.
In practice this is not the best idea because there are a tremendous number of possible rules
and the state space we'd have to reason about is very large.
And humans typically focus in on one part of the overall problem at a time, anyway.
We call these subsets of the problem state *contexts*.
There are many possible choices for contexts in nonograms, but one common one is a single row or line.
We focus exclusively on these line contexts.
The transition function can be straightforwardly defined over lines, and our DSL will work over lines.

A *line context* *c* is defined by its hints *hints(c) = h1,...hk* where *hi in N*
and its partial board state *cells(c) = c1,...cn* where *ci = {true,false,empty}*.

Given a set of rules or a transition function one lines, we can solve (most but not all)
full problems by applying every possible rule to every possible line until exhaustion.
Rules can also be applied to flipped lines since lines are symmetric.

## A DSL for Rules on Line Contexts

Procedural rules consist of 3 parts:

- Parameters describing where a rule is applied
- A condition describing when a rule may be applied
- An action describe how a rule is applied

Here, we will call these the *binding*, *condition*, and *action*, respectively.
This is the same formalism we used for the algebra domain.

An example (in natural) language of a nonograms rule (where *N* is shorthand for the length of the line):

    binding: For any arbitrary hint with value h,
    condition: If 2h > N,
    action: Then fill "true" in for all cells in the range [N-h, h).

### Grammar

    program ::= (Program bindseq cond action)
    bindseq ::= binding+
    binding ::= (NoBinding)
        | (Singleton lst) | (Constant lst int) | (Arbitrary lst)
    cond ::= True | (And cond cond) | (Filled? int bool)
        | (Apply compop expr expr) | (Unique? int cond)
    action ::= (Fill bool expr expr expr)
    expr ::= (Const int) | N | (Length lst) | (Apply arithop expr expr)
        | (BindingIndex int) | (BindingValue int) | (BoundValue)
        | (LowesetEndCell int) | (HighestStartCell int)
        | (Max lst) | (Min lst)
    compop ::= > | >= | =
    arithop ::= + | -
    lst ::= Hint | Gap | Block
    int ::= integer literal
    bool ::= boolean literal

### Semantics

Rules are partial functions from line contexts to line contexts.
They can assign bindings non-deterministically, so here we will
consider those non-deterministic choices as inputs in a deterministic semantics.
We write *[R](t,b)* to mean the rule R applied to the line context *t* with
a sequence of non-deterministic choices *b*,
with the functions *hints* and *cells* as defined previously,
and the shorthands *hi* as the ith hint, *ci* as the ith cell,
*n* as |cells(t)|, and *k* as |hints(t)|.

Also to define *gaps* and *blocks*:
A *gap* is a contiguous run of cells that are not *false* (either *true* or *empty*)
and a *block* is a contiguous run of cells that are *true*.
*gaps(t)* is the sequence of pairs of start indices and lengths of all gaps,
and similarly with blocks.


    [(Program (B1,..Bm) c a)](t, b1,...bm)
                                = if (∀1≤i≤m [Bi](t,bi)) ^ [c](t,(makebinding(B1,t,b1),...,makebinding(Bm,t,bm))
                                  then [a](t,(makebinding(B1,t,b1),...,makebinding(Bm,t,bm)) else ⊥

    [(NoBinding)](t,i)          = true
    [(Singleton lst)](t,i)      = i = 0 ^ 1 = |bindinglist(t,lst)|
    [(Constant lst v)](t,i)     = i = v ^ 0 ≤ v < |bindinglist(t,lst)|
    [(Arbitrary lst)](t,i)      = 0 ≤ i < |bindinglist(t,lst)|

    [(Fill v o s e)](t,b)       = fill(t,v,[o](t,b),[s](t,b),[e](t,b))

    [true](t,b)                 = true
    [(And e1 e2)](t,b)          = [e1](t,b) ^ [e2](t,b)

    [(Apply op e1 e2)](t,b)     = [op]([e1](t,b), [e2](t,b))
    [(Const x)](t,b)            = x
    [N](t,b)                    = n
    [(Length lst)](t,b)         = |bindinglist(t, lst)|

    [(BindingIndex i)](t,b)     = index(b_i)
    [(BindingValue i)](t,b)     = value(b_i)
    [(BoundValue)](t,b)         = value(last(b))

    [(LowesetEndCell e)](t,b)   = loweststart(cells(t),[e](t,b))
    [(HighestStartCell e)](t,b) = highestend(cells(t),[e](t,b))

    [(Unique? vidx e)](t,b)     = 1 = |{ x=(k,v) | [e](t,b extended with (k,v,blist(b_vidx))), x in blist(b_vidx) }|
    [(Filled? e v)](t,b)        = cells(t)_[e](t,b) = v

    bindinglist(t, Hint)        = i,hi for i in [0,k)
    bindinglist(t, Gap)         = gaps(t)
    bindinglist(t, Block)       = blocks(t)

    makebinding((NoBinding),t,i)
                                = (0,0,none)
    makebinding(B,t,i)          = let k,v = bindinglist(t,listof(B))_i in (k,v,bindinglist(listof(B)))
    index((i,_,_))              = i
    value((_,v,_))              = v
    blist((_,_,b))              = b

    listof(elem)                = if elem = (Singleton lst) then lst 
                                  if elem = (Constant lst v) then lst
                                  if elem = (Arbitrary lst) then lst
                                  otherwise ⊥
    loweststart(c,i)            = the least i such that hi could occupy ci on any line of length n (ignoring cells)
    highestend(c,i)             = one plus the greatest i such that hi could occupy ci on any line of length n (ignoring cells)

    fill(t,v,o,s,e)             = t with cells(t) modified s.t. the cells in the range [o+s,o+e) have value v.

## Synthesizing/Verifying Programs

basic algo:

    for i,o in states:
        let b0 = most-specific-binding(i)
        for b in subset(b0): # typically bounded up to a certain size
            if exists-rule-with-this-binding(i):
                ...

What do we do if there was a rule using a subset of bindings?
Is it possible that there is a better rule so we should try anyway? Should we assert it's used?
Give up because we already found something? Especially since thi is what we do for other, covered contexts?

Can we tell if there is a *possible* rule, only looking at the binding?
Anything not mentioned by the binding can be relaxed, which changes to the potential output.
For a *fixed* output, this seems straightforward:
does there exist input `i'` that is consistent with `i` on the fixed bindings for which `o` is not determined?
Can find `i'` and `o'` with the same query, it's pretty easy to set that up.
Then we assert that `o'` is not consistent (or maybe equal?) with `o`.

This gets a lot tricker if we haven't totally fixed `o` because we're aiming for just some substate of `o`.
So finding something partially inconsistent isn't really a bad thing.
In the past we were arbitrarily fixing `o` but it would be highly desierable to move away from this and find the "best" possible output.
Or you know whatever just search over all possible outputs, there aren't *that* many.
Bidirectional search! We can make it better later.

Can we do the same trick for algebra?
We don't actually *need* to do this for algebra, we know for certain that the most specific binding works,
and we have a pretty efficient policy for searching all of the more general bindings.
The issue shows up when we start immediately trying to restrict the bindings before searching for rules.
That's what makes it slow.
But now we have a policy huzzah, we can find rules.

For algebra, we had a fully specified function (the "synthesis" was more a superoptimization),
and therefore we could separate condition/action learning.
With nonograms, it's hilariously underspecified, so we must do them together.

This rule learning is kinda an endless process, because we keep upping the limits and adding new transitions/iopairs to cover holes.
So should probably record what we have tried + limits in the past to keep track.
Event on success, we might want to increase the limits in case the limits were preventing significant generalization.
Also maybe we should try a non-greedy generalization-optimization? Or just keep with greedy for now, and try a different one iteratively.

## Some amusing problems

With this find-a-binding-first approach, we can't express the 0-hint case!
Can fix this by representing it as a hint value with 0 rather than no hints, I think.
This is how it's displayed in all representations anyway.

Something we'll probably have to do:
synthesize the bindings in order (of subset) and ensure programs with more bindings
find strictly more general rules than the one with fewer bindings.
This saves a lot of time, because right now all the 2-binding programs just take 5+ minutes.

We need to torch all external references to the state in the rules.
No Ks, Bs, etc. No Max.
But Max? is okay, fits right along with Unique?
Can we suffer N? Since it's more of a constant rather than a part of the state, maybe?
Can we work K back in somehow? As part of the binding?
It is a constraint! There's no ladder but eh.


