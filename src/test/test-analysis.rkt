#lang racket

(require
  rackunit rackunit/text-ui
  "../core/core.rkt"
  "../nonograms/nonograms.rkt"
  "../learn/analysis.rkt")

(define (test-binding-less-general b1 b2 expected)
  (test-case (format "less-~v-~v" b1 b2)
    (check-equal? (binding-less-general? b1 b2) expected)))

(void (run-tests (test-suite
  "analysis"

  (test-binding-less-general (list (Constant #f 0)) (list (Singleton #f)) #f)
  (test-binding-less-general (list (Singleton #f)) (list (Constant #f 0)) #t)

  (test-binding-less-general (list (NoBinding) (Constant #f 0)) (list (NoBinding) (Singleton #f)) #f)
  (test-binding-less-general (list (NoBinding) (Singleton #f)) (list (NoBinding) (Constant #f 0)) #t)

  (test-binding-less-general (list (Constant #f 0) (Singleton #f)) (list (Constant #f 0) (Constant #f 0)) #t)
  (test-binding-less-general (list (Constant #f 0) (Singleton #f)) (list (Singleton #f) (Constant #f 0)) #f)

  )))
