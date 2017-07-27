#lang racket
; tests for board solving

(require
  rackunit rackunit/text-ui
  "../core/core.rkt"
  "../nonograms/nonograms.rkt"
  "../nonograms/dsl-pretty.rkt"
  "../nonograms/debug.rkt"
  "../nonograms/builtin.rkt"
  "../learn/solve.rkt")

(define (test-solvable? rules brd expected)
  (test-case (format "board-solvable? ~a" brd)
    (check-equal? (board-solvable-with-rules? rules brd) expected)))

(define (test-find-transition rules ctx expected)
  (test-case (format "find-transition ~a" ctx)
    (check-equal? (find-maximal-transition-with-rules rules ctx) expected)))

(define r-empty-row
  (program
    (Constant 'gap 0)
    (app = K C0)
    (Fill #f C0 C0 N)))

(define r-fill-only-large-enough-gap
  (Program
    (list
      (Arbitrary 'hint)
      (Arbitrary 'gap))
    (And
      (Unique? 1 (app >= (BoundValue) (BindingValue 0)))
      (app = (BindingValue 0) (BindingValue 1)))
    (Fill #t (BindingIndex 1) C0 (BindingValue 1))))

(void (run-tests (test-suite
  "nonograms-board-solving-with-rules"

  (let ([brd (make-empty-board '(()()()()) '(()()()()))])
    (test-solvable? (list r-empty-row) brd #t))

  (let ([brd (make-empty-board '((1)()()()) '((1)()()()))])
    (test-solvable? (list r-empty-row) brd #f))

  (let ([ln (make-line '() "------")])
    (test-find-transition (list r-empty-row) ln (make-transition '() "------" "xxxxxx")))

  (let ([ln (make-line '(5) "-----")])
    (test-find-transition (list r-fill-only-large-enough-gap) ln (make-transition '(5) "-----" "OOOOO")))

  (let ([ln (make-line '(2 3) "--x---")])
    (test-find-transition (list r-fill-only-large-enough-gap) ln (make-transition '(2 3) "--x---" "OOxOOO")))

  )))

(define (test-find-ssm ctx expected)
  (test-case (format "subspace-find-~a" ctx)
    (check-equal? (find-subspace-mappings ctx) expected)))

(define (test-apply-ssm ssm data expected)
  (test-case (format "subspace-apply-~a" data)
    (define actual
      (cond
       [(line? data) (apply-subspace-mapping ssm data)]
       [(line-transition? data) (apply-subspace-mapping-t ssm data)]))
    (check-equal? actual expected)))

(define (test-reverse-ssm ssm orig data expected)
  (test-case (format "subspace-reverse-~a" data)
    (check-equal? (reverse-subspace-mapping ssm orig data) expected)))

(define (test-reverse-ssm-a ssm data expected)
  (test-case (format "subspace-reverse-action~a" data)
    (check-equal? (reverse-subspace-mapping-a ssm data) expected)))

(define (test-compose-ssm ssm1 ssm2 data)
  (test-case (format "composing-subspace-mapping-~a-~a" ssm1 ssm2)
    (check-equal?
      (apply-subspace-mapping (compose-subspace-mappings ssm1 ssm2) data)
      (apply-subspace-mapping ssm1 (apply-subspace-mapping ssm2 data)))))

(void (run-tests (test-suite
  "subspace mappings"
  (test-find-ssm (make-line '() "------") empty)
  (test-find-ssm (make-line '(5) "------") empty)
  (test-find-ssm (make-line '(1 1) "--O---") empty)
  (test-find-ssm (make-line '(1 1) "-O----") (list (subspace-mapping '(0 . 1) '(0 . 2)) (subspace-mapping '(1 . 2) '(3 . 6))))
  (test-find-ssm (make-line '(1 1) "----O-") (list (subspace-mapping '(0 . 1) '(0 . 3)) (subspace-mapping '(1 . 2) '(4 . 6))))
  (test-find-ssm (make-line '(1 1) "O-----") (list (subspace-mapping '(1 . 2) '(2 . 6))))
  (test-find-ssm (make-line '(1 1) "-----O") (list (subspace-mapping '(0 . 1) '(0 . 4))))
  (test-find-ssm (make-line '(1 1 1) "O----O") (list (subspace-mapping '(1 . 2) '(2 . 4))))
  (test-find-ssm (make-line '(1 1 1 1) "O----O---") (list (subspace-mapping '(1 . 2) '(2 . 4)) (subspace-mapping '(3 . 4) '(7 . 9))))
  (test-find-ssm (make-line '(2 1) "-O----") empty)
  (test-find-ssm (make-line '(1 2) "----O-") empty)

  ; some cases that the old algorithm produces unsound subspaces, have to also check that blocks are definitely not part of the reduced space
  (test-find-ssm (make-line '(3 6) "-----O--OOO---") empty)
  (test-find-ssm (make-line '(3 6) "----O---OOO---") empty)

  (test-apply-ssm (subspace-mapping '(1 . 2) '(3 . 6)) (make-line '(1 1) "-O----") (make-line '(1) "---"))
  (test-apply-ssm (subspace-mapping '(1 . 2) '(3 . 6)) (make-transition '(1 1) "-O----" "xOx-xx") (make-transition '(1) "---" "-xx"))
  (test-reverse-ssm (subspace-mapping '(1 . 2) '(3 . 6)) (make-line '(1 1) "-O----") (make-line '(1) "xO-") (make-line '(1 1) "-O-xO-"))
  (test-reverse-ssm-a (subspace-mapping '(1 . 2) '(3 . 6)) (fill-action #t 1 2) (fill-action #t 4 5))
  (test-reverse-ssm-a (subspace-mapping '(1 . 2) '(3 . 6)) (fill-action #f 0 1) (fill-action #f 3 4))
  (test-reverse-ssm-a (subspace-mapping '(1 . 2) '(3 . 6)) (fill-action #t 0 2) (fill-action #t 3 5))

  (test-compose-ssm (subspace-mapping '(2 . 4) '(1 . 5)) (subspace-mapping '(1 . 5) '(2 . 10)) (make-line '(1 2 3 4 3 2) "--xxOO---xxxOOO----xxxx"))
  (test-compose-ssm (subspace-mapping '(3 . 4) '(4 . 6)) (subspace-mapping '(1 . 5) '(2 . 10)) (make-line '(1 2 3 4 3 2) "--xxOO---xxxOOO----xxxx"))
  (test-compose-ssm (subspace-mapping '(2 . 4) '(1 . 5)) (subspace-mapping '(2 . 6) '(5 . 15)) (make-line '(1 2 3 4 3 2) "--xxOO---xxxOOO----xxxx"))

  )))

