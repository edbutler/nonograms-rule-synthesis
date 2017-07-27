#lang racket

(require
  rackunit
  rackunit/text-ui
  "../core/core.rkt"
  "../nonograms/nonograms.rkt"
  "../nonograms/builtin.rkt"
  "../nonograms/dsl-pretty.rkt"
  "../learn/synthesize.rkt")

(define-simple-check (check-sketch-covers? features program)
  (parameterize ([current-sketch-features features])
    (sketch-covers? program (void))))

(define-simple-check (check-not-sketch-covers? features program)
  (parameterize ([current-sketch-features features])
    (not (sketch-covers? program (void)))))

(void (run-tests (test-suite
  "sketches"

  (test-case "builtins"
    (for ([be all-builtin-rules])
      (match-define (builtin name prog examples) be)
      (check-sketch-covers? default-program-features prog)))

  (test-case "basic prog"
    (define p (program (Constant 'gap 0) (True) (Fill #f C0 C0 C1)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base) p)
    );(check-not-sketch-covers? empty p))

  (test-case "arithmetic prog + d"
    (define p (program (Constant 'gap 0) (True) (Fill #f C0 (a+ C0 C0) C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-arithmetic) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "arithmetic prog + p"
    (define p (program (Constant 'gap 0) (True) (Fill #f (a+ C0 C0) C0 C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-arithmetic) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "arithmetic prog - d"
    (define p (program (Constant 'gap 0) (True) (Fill #f C0 (a- C0 C0) C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-arithmetic) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "arithmetic prog - p"
    (define p (program (Constant 'gap 0) (True) (Fill #f (a- C0 C0) C0 C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-arithmetic) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "comparison prog ="
    (define p (program (Constant 'gap 0) (a= C0 C0) (Fill #f C0 C0 C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-comparison) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "comparison prog >="
    (define p (program (Constant 'gap 0) (a>= C0 C0) (Fill #f C0 C0 C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-comparison) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "comparison prog >"
    (define p (program (Constant 'gap 0) (a> C0 C0) (Fill #f C0 C0 C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-comparison) p)
    (check-not-sketch-covers? (list feature-base) p))

  (test-case "comparison & arithmetic"
    (define p (program (Constant 'gap 0) (a> C0 C0) (Fill #f C0 (a+ C0 C0) C0)))
    (check-sketch-covers? all-program-features p)
    (check-sketch-covers? (list feature-base feature-comparison feature-arithmetic) p)
    (check-not-sketch-covers? (list feature-base feature-comparison) p)
    (check-not-sketch-covers? (list feature-base feature-arithmetic) p)
    (check-not-sketch-covers? (list feature-base) p))

  )))
