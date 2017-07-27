#lang racket

(require
  "util.rkt"
  "../core/core.rkt"
  "../nonograms/dsl-pretty.rkt"
  "../nonograms/debug.rkt"
  "../nonograms/builtin.rkt"
  "../nonograms/nonograms.rkt"
  "../learn/coverage.rkt"
  rackunit
  rackunit/text-ui)

(define (check-fixed-point rules transitions expected-changed expected-new)
  (define-values (total-changed new-transitions) (apply-rules-to-fixed-point-of-set transitions rules))
  (check-equal? total-changed expected-changed)
  (check-set=? new-transitions expected-new))

(define-simple-check (check-program-coverage prog transitions expected)
  (define envs (map (compose create-environment line-transition-start) transitions))
  (= expected (coverage-of-rule envs prog)))

(define-simple-check (check-programs-coverage progs transitions expected)
  (= expected (coverage-of-rules transitions progs)))

(define (test-coverage rule transitions expected)
  (test-case (format "coverage ~a ~a" rule transitions)
    (check-program-coverage rule transitions expected)))

(define (test-coverage-set rules transitions expected)
  (test-case (format "coverage ~a ~a" rules transitions)
    (check-programs-coverage rules transitions expected)))

(define t0 (make-transition '(5) "-----" "OOOOO"))
(define t1 (make-transition '(5) "OOOO-" "OOOOO"))
(define t2 (make-transition '(2 2) "-----" "OOxOO"))

(void (run-tests (test-suite
  "program coverage analysis"

  (let ([p (program (Arbitrary 'hint) (True) (Fill #t C0 C0 C1))]
        [p2 (program (Arbitrary 'hint) (True) (Fill #t C1 C0 C1))]
        [p3 (program (Arbitrary 'block) (a> N BV) (Fill #t (a+ BI BV) C0 C1))])
    (test-case "basic"
      (check-equal? (apply-rules-to-fixed-point (list p) t0) (make-line '(5) "O----"))
      (check-equal? (apply-rules-to-fixed-point (list p) t0) (make-line '(5) "O----"))
      (check-fixed-point (list p) (list t0) 1 (list (make-transition '(5) "O----" "OOOOO")))
      (check-fixed-point (list p2) (list t0) 1 (list (make-transition '(5) "-O---" "OOOOO")))
      (check-fixed-point (list p p2) (list t0) 2 (list (make-transition '(5) "OO---" "OOOOO")))
      (check-fixed-point (list p) (list t1) 0 empty)
      )
    (test-case "fancy"
      (check-fixed-point (list p) (list t2) 1 (list (make-transition '(2 2) "O----" "OOxOO")))
      (check-fixed-point (list p p2) (list t2) 2 (list (make-transition '(2 2) "OO---" "OOxOO")))
      )
    (test-case "recursive"
      (check-equal? (apply-rules-to-fixed-point (list p p3) t0) (make-line '(5) "OOOOO"))
      )

    (test-coverage p (list t0) 1)
    (test-coverage-set (list p) (list t0) 1)
    (test-coverage p (list t1) 0)
    (test-coverage-set (list p) (list t1) 0)
    (test-coverage-set (list p p2) (list t2) 4)
    )

  )))

