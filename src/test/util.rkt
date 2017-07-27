#lang racket

(provide (all-defined-out))

(require rackunit)

(define-binary-check (check-set=? set=? actual expected))
(define-binary-check (check-not-set=? actual expected) (not (set=? actual expected)))

