#lang rosette

(require
  rackunit rackunit/text-ui
  "../core/core.rkt")

(define (test-serialize o)
  (test-case (format "serialize-~a" o)
    (define s (serialize o))
    (check-pred place-message-allowed? s)
    (check-equal? o (deserialize s))
    (define x (read-from-string (format "~s" s)))
    (check-equal? o (deserialize x))))

(void (run-tests (test-suite
  "synth"

  (test-case "symbolic?"
    (define-symbolic x integer?)
    (define-symbolic y boolean?)
    (define-symbolic z integer?)
    (define not-symbolic? (compose not symbolic?))
    (check-pred symbolic? (cons x x))
    (check-pred symbolic? (cons x x))
    (check-pred symbolic? (if (= x z) (not y) #t))
    (check-pred symbolic? (if (= x z) #t 3))
    (check-pred not-symbolic? 2)
    (check-pred not-symbolic? (cons 3 4))
    )

  )))

(standard-struct st (a b))

(void (run-tests (test-suite
  "serialization"

  (test-serialize 2)
  (test-serialize #f)
  (test-serialize 'sym)
  (test-serialize "str")
  (test-serialize '(1 2 (3 4)))
  (test-serialize (st "a" "b"))
  (test-serialize (vector 1 (vector 2)))
  (test-serialize (vector (list 1 2) (st (st (list 1 'sym) #t) (vector "happy"))))
  (test-serialize (hasheq 'a 2 3 (st "a" "b")))

)))

