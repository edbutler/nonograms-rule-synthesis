
| Rule Name                   | Covered? | Test Transitions Covered by Next Best | Potential Training Examples |
| --------------------------- | -------- | ------------------- | --------------------------- |
| `full-hint`                 | yes      |                     | 8  |
| `big-hint`                  | yes      |                     | 44 |
| `edge-fill`                 | **NO**   | 518 / 1330          | 4  |
| `full-edge-gap`             | **NO**   | 245 / 956           | 1  |
| `cross-small-gap-singleton` | yes      |                     | 8  |
| `cross-small-gap-min`       | yes      |                     | 7  | 
| `cross-small-gap-left`      | yes      |                     | 2  |
| `punctuate-max`             | yes      |                     | 24 |
| `punctuate-hint0`           | **NO**   | N/A                 | **0** |
| `mercury`                   | **NO**   | N/A                 | **0** |
| `force-max`                 | **NO**   | 1104 / 1832         | 47 |
| `no-hints`                  | **NO**   | N/A                 | **0** |

NOTE: the "next best rule" is the single rule learned from a potential training example that covers most of the test cases.
So it's a measure of how badly we missed learning this rule. It does not count how well these examples are covered by *other* rules.

`no-hints` is inexpressible without allowing hint count in conditions. We took this out because we wanted all information in bindings.
Since bindings can only be expressed exestentially (there isn't a "there are no hints" binding), this rule cannot be expressed in our DSL.

`mercury` and `punctuate-hint0`, while parially applicable on small states, need larger canonical states to find example applications that match exactly.

`full-edge-gap` had only one matching example: `(line (2) "O---")` to `(line (2) "OO--")`.
It appears to have generalized in a different direction. Since the action only filled one cell there is a lot of ambiguity for potential arithmetic expressions to fill it.

`force-max` is similar; there are a lot of examples of a specialized case, and the learner runs off in a different direction with generalization.
