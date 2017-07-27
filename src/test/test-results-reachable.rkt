#lang racket

; checks if the results achieved during the FDG17 paper are still possible, to test for regressions.

(require
  rackunit
  rackunit/text-ui
  "../config.rkt"
  "../core/core.rkt"
  "../nonograms/nonograms.rkt"
  "../nonograms/builtin.rkt"
  "../nonograms/dsl-pretty.rkt"
  "../learn/synthesize.rkt")

; This is just so it shows the program in the UI on failure. We already know the result.
(define-simple-check (check-program-covered? program result) result)

(define (test-sketch-covers? features program)
  (parameterize ([current-sketch-features features])
    (sketch-covers? program (void))))

(load-config 'analyze)

(define (test-items idx items)
  (evaluate-in-subprocess "src/test/aux-results-reachable.rkt" "(run)" items))

(void (run-tests (test-suite
  "sketches of original rules"
  (let ([rules (deserialize-from-file (config-pathref 'compacted-results))])
    (define results
      (parameterize ([current-parallel-worker-count 7])
        (run-batches/parallel test-items rules #:batch-size 10)))

    (for ([pr results])
      (test-case (format "~a" (car pr))
        (check-program-covered? (car pr) (cdr pr))))

    ))))

