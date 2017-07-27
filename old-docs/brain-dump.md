# Dumping info post ijcai to pick this up later


We left off in the middle of writing a paper.

## The planned intro story:

- Explainable AI is important
- We want to make this thing learn explainable rules for solving nonograms
- Explainable means humans can interpret it
- To that end, we're going to model this as a programming language, then do PS.

## Remaining Work, if we have time:

- Try to generalize in *all* ways (for at least on small test case).
    - Probably infeasible in general, but then we can argue waiting longer would be effective.
    - Good candidate is the 2-length line -O -> xO, lots of control rules apply in this case.
- An optimization objective that includes considering rule cost.
- More test data (some is not chosen randomly).
    - In particular, maybe more book sources.
- More ground truth rules from books.
    - We only have, effectively, 10.

