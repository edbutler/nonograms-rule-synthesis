#lang racket

(require
  rackunit rackunit/text-ui
  "../core/core.rkt")

(define (test-choices k lst expected)
  (test-case (format "choices-~a-~a" k lst)
    (check-true (set=? (choices lst k) expected))))

(define (test-choices-up-to k lst expected)
  (test-case (format "choices-~a-~a" k lst)
    (check-true (set=? (choices-up-to lst k) expected))))

(void (run-tests (test-suite
  "math"

  (test-choices 1 empty '())
  (test-choices 0 empty '(()))
  (test-choices 0 '(1) '(()))
  (test-choices 1 '(1) '((1)))
  (test-choices 1 '(1 2) '((1) (2)))
  (test-choices 2 '(1 2) '((1 2)))
  (test-choices 2 '(1 2 3) '((1 2) (1 3) (2 3)))
  (test-choices 3 '(1 2 3) '((1 2 3)))

  ; just to make sure it works with non-integers and duplicates
  (test-choices 2 '(#f "a" "a") '((#f "a") (#f "a") ("a" "a")))

  (test-choices-up-to 1 '(1) '((1)))
  (test-choices-up-to 2 '(1 2) '((1) (2) (1 2)))
  (test-choices-up-to 2 '(1 2 3) '((1) (2) (3) (1 2) (1 3) (2 3)))
  (test-choices-up-to 3 '(1 2 3) '((1) (2) (3) (1 2) (1 3) (2 3) (1 2 3)))

  )))

