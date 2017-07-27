
# Nonograms! #

## What is this project about? ##

Computer-aided design of procedural knowledge for Nonograms.
In particular, trying to apply the approach we used for algebra for logic puzzles.

## Overview of the Problem ##

### What is the problem statement (and in what way is this similar to algebra)?

Our problem is the same broad one. Namely, given a:
- problem domain (with some formal description of the rules).
- DSL for representing rules in problem domain.
- objective function ranking rule sets.
- any other parameters needed for the objective function (e.g., sample problems).

We need to find an optimial(ish) ruleset according to the objective function.

For algebra, these pieces were, more specifically:
- a set of axioms (implemented in the DSL) and a goal predicate.
- our tree-rewrite DSL.
- objective functions that could vary, but mainly balanced rule set complexity and solution efficiency.
- a set of example problems (both to help rule learning and because the objective function was defined over it).

Our algorithm for algebra could be basically summed as (1) use the example problems to mine a bunch of possible specs for rules (2) learn a lot of rules (3) pick the best subset.

We should note that this problem statement is a little stronger than we need it to be. We aren't looking for a truely optimal rule set so much as we want to synthesize a bunch of potentially useful rules, biasing our search using the objective function since the space of possible rules in enormously intractible. This is really important for logic puzzles since finding a true optimial value is probably not feasible as it was with algebra.

### What makes logic puzzles harder than algebra?

We had two crucial tricks that made algebra tractible, neither of which is available for logic puzzles. First, algebra is easily axiomatized, and, crucially, many useful rules are straightforward macros of these axioms. So the space of rules we need to consider is the possible combinations of axioms. We constrained this even further by looking at the solutions for the example problems and only considering macros that showed up in these grpahs. The number of possible solutions for an arbitrary (small) algebra problem is quite limited. On the other hand, with puzzle games, there's generally only one axiom (does the deduction preserve the invariants in all possible solutions) and all advanced rules are special cases of this general rule. The generality of a rule can be expressed by the number of contexts (possible partially-solved puzzle states) to which a rule applies. Thus we have an entire powerset of possible game states to search over for rules. Unlike algebra, we can't exploit the natrual partitioning of game states provided by the axioms. To ruin the second part of the trick, even very simple boards have a huge number of solutions because the rules can be applied in any order, so the manner in which we used example problems for algebra will not work here.

The second crucial trick to make learning algebra rules tractible was designing a DSL whose structure could be exploited so search for sound/complete rules efficiently. Algebra rules' DSL is a tree-rewrite language. The primary exploitable aspect was a pattern-based condition. Given a single concrete example we want to synthesize a rule for, we can easily enumerate the space of all possible patterns that could apply to this example, dramatically improving the efficiency of rule search over a naive approach. Any approach for puzzles that hopes to be tractible must use some equivalent trick, though, these are of course specific to the DSL used. Since many puzzles will probably require custom DSLs, it's worth considering how we can generlize this optimization (or exploit existing work) to make efficient sketches for more arbitrary DSLs.

### Properties of Logic Puzzles

Or, what are the common features of the domain that we must consider to build general methods to learn rules for logic puzzles?

Logic puzzles in general are a very weird game domain. Many popular puzzles (e.g., Sudoku and Nonograms) are NP-hard on hypothetical infinite sizes. Even restricted to finite problems, an algorithm for solving puzzles that doesn't resort to exponential search of some kind would be hilariously complicated. Based on the writings of puzzle designers, we can conclude that backtracking search is not an ideal mechanism for humans to solve these puzzles. More strongly, these writings suggest that designers consider a puzzle a failed design if it requires search. Which suggests people are using some kind of greedy algorithm to solve the puzzles. We can conclude then that the algorithms people use to solve NP-hard puzzles would not succeed in solving aribtrary puzzles even in the finite spaces used because the number of tricks availble are not high enough. From this it appears that puzzle design chooses an polynomial subspace of the domain and only creates puzzles in that space. It is unclear how arbitrary this space is: did it arise more from historical accident or human psychology?

This leads to a very interesting implication for rule learning: the goal isn't to learn rules that solve any puzzle (up to finite bounds), but to pick a set of rules that can solve a substantial subspace of these puzzles with a small number of rules. In fact, depending on how much this subspace is determined by psychology or other modelable factors, we could attempt to choose this subspace along with the rules. So our problem becomes one of "find as many rules as we can, biasing ourselves toward 'good' rules because we don't want very many, then just take whatever design space these rules can express."

### Why nonograms?

...as opposed to, say Sudoku?
Our choice of puzzle game for the work is partially arbitrary; we're interested in exploring properties of logic puzzles in general and how we can do automated rule learning for them. All else being equal, though, more popular games would be better, so Sudoku seems like a great choice. However, after the amount of effort that was spent dealing with symmetries in algebra, it would probably be wise to start with a puzzle that has a more straightforward representation. Nonogram's state space is a boolean array, as simple as can possibly be. Sudoku is an array of sets of numbers, and, worse, the numbers are arbitrary labels so every puzzle has 9! isomorphic puzzles just from number relabling, not even considering the D4 group symmetries of board rotation/flipping. The nonograms booleans are, however, not symmetric, and we can constrain ourselves to considering one row/column at a time, leaving only 1 apparent symmetry (row flipping).

## Background on Nonograms ##

### Rules of the Game

Nonograms (also known as Picross, among other names) is a picture logic puzzle. Each puzzle is a 2D binary array (grid) of cells, where black is used to represented "on" and white "off." Typically puzzle solutions form some kind of a interpretable picture, e.g., a flower. The puzzle begins with an unfilled grid. Hints consist of sequences of integers associated with each row or column. For a given row/column, its associated hint is either a 0 or a list of one or more positive integers. If the hint is 0, then the entire row/column's cells are "off." If the hint is the sequence [h1, ..., hk], then the row consists of h1+...+hk "on" cells, separated into k separate runs of contiguous on blocks with at least one off block in between. Thus, for example, on a grid with row length 10, if row 1 has the hint [4,5], the only solution is that the first 4 cells are on, the 5th off, and the remaining 5 on. Like many other logic puzzles, solutions in nonograms must be unique. The general variant of the puzzle on arbitrary-sized grids is [NP-complete](http://liacs.leidenuniv.nl/assets/2012-01JanvanRijn.pdf).

### Refining the Problem Statement for Nonograms

As previously stated, our input for nonograms is different than for algebra. We do not have a set of axioms on which to find macros, and, even if we chose one, the sets of possibly useful rules are myriad and overlapping, unlike the clean partitioning seen in algebra. First, some preliminaries so we can be more precise about "useful rules" and "overlapping."

The class of problem domains we are going to call "logic puzzles" share the following properties:

## Current Progress / Technical Details

We have a sound decision procedure for:
given a set of (row) deductions, return the smallest sound program that executes those deductions, or none if one does not exist.

Quick thought: when finding rules, they can use the action to do redundant things if the program is cheaper, and this is okay.
But asserting that the program interprets exactly to the action will not allow this.

Super great nonograms web resource:
http://webpbn.com/index.cgi?page=solving.html

Thinking about how we can exploit language for better sketches.
Two problems:

- Too many counter examples required (making silly guesses)
- Too large of a program space over which to search (not taking advantage of positive example)

part of these are hard constraints but some of it is very soft, hard to add in.
e.g., why bother searching for programs that reference gap size in the action but not the condition?

Some ideas for more constraints that may reduce # counter examples:

- No using identifiers in the action unless they are referenced in the condition.

- Marking certain integers are availble only for comparison rather than adding.
  (in general, a more sophisticated type system)

