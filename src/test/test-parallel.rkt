#lang racket

; testing the thread parallelism

(require
  rackunit
  rackunit/text-ui
  "util.rkt"
  "../core/core.rkt")

(define (test-parmap f lst)
  (check-set=? (parallel-map/thread f lst) (map f lst)))

(void (run-tests (test-suite
  "parallel"

  (test-case "simple"
    (let ([lst '(1 2 3 4 5 6 7 8 9)])
      (test-parmap identity lst)
      (test-parmap add1 lst)
      (test-parmap (λ (x) (cons x 45)) lst)
      (void)))

  )))
