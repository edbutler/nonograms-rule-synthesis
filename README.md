
# Nonograms Rule Synthesis

The source code used in the publication [Synthesizing Interpretable Strategies for Solving Puzzle Games](https://www.ericbutler.net/assets/papers/fdg2017_puzzle.pdf).

## Installation

Requires [Racket 6.9](http://racket-lang.org/) or higher, and a recent version of the [Rosette](https://github.com/emina/rosette) library. The code will run on any major desktop OS, but experience is likely to be best on a POSIX system.

First, optionally, build the project files for faster startup by running the following form the root directory:

    $ raco make src/*.rkt

## Usage

To run the learning algorithm, execute the following commands, from the root directory. The scripts require a configuration file, which can be found in `config/`. Both `config/toy.json` and `config/sample.json` use dramatically smaller training sets and program search spaces than the configuration used for the paper (so take dramatically less time to run). The `toy.json` version uses all states with lines up to length 2, while `sample.json` uses random states with lines up to length 6. The configuration files can be modified to, e.g., change the number of worker threads. By default they assume an 8-core processor. For the `sample.json` config, run:

    $ ./do-learning.sh config/sample.json

This will potentially take hours to finish. To analyze the results:

    $ ./do-analysis.sh config/sample.json

This will create a file `html/results.html` showing the top 10 (or less than 10 if a full cover was reached) synthesized rules as selected by the optimization algorithm. This will also create a file `html/builtins.html` that shows the manually transcribed control rules. The rules synthesized with the sample configuration are unlikely to be better than the control rules due to the small training size.

## Other Information

The data (including the testing set, synthesized rules, and analyzed results) used in the paper's evaluation are in `paper-data/`. The synthesized rule data file also includes, along with the rules themselves, the training item used to synthesize each rule.

The visualization code uses Font Awesome by Dave Gandy - http://fontawesome.io.

