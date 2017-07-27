#lang rosette

(require
  rackunit rackunit/text-ui
  "../core/core.rkt"
  "../nonograms/nonograms.rkt"
  "../nonograms/debug.rkt")

(define (test-sym-ctx-solved len)
  (test-case (format "symbolic-lines-solved-~a" len)
    (parameterize-solver
      (define tctx (symbolic-line-transition len))
      (define soln (solve (assert (not (line-solved? (line-transition-end tctx))))))
      (check-pred unsat? soln))))

(define (test-sym-segs fn ctx expected)
  (test-case (format "sym-~a-of-~v" fn ctx)
    (parameterize-solver
      (define f (match fn ['gaps gaps-of-line] ['blocks blocks-of-line]))
      (define sym-segs (f ctx #:symbolic? #t))
      (define segs (evaluate sym-segs (solve (assert #t))))
      (check-equal? segs expected))))

(define (seg s e) (segment s e #t))

(void (run-tests (test-suite
  "nonograms-symbolics"
    (test-sym-ctx-solved 1)
    (test-sym-ctx-solved 3)
    (test-sym-ctx-solved 5)

    (test-case "any-symbolic-line"
      (parameterize-solver
        (define tctx (symbolic-line-transition 5))
        (define soln (solve (assert #t)))
        (check-pred sat? soln)
        (check-pred line-transition? (evaluate tctx soln))))
    (test-case "any-unsolved-symbolic-line"
      (parameterize-solver
        (define tctx (symbolic-line-transition 5))
        (define soln (solve (assert (not (line-solved? (line-transition-start tctx))))))
        (check-pred sat? soln)
        (check-pred line-transition? (evaluate tctx soln))))
    (test-case "any-solved-symbolic-line"
      (parameterize-solver
        (define tctx (symbolic-line-transition 5))
        (define soln (solve (assert (not (equal? (line-transition-start tctx) (line-transition-end tctx))))))
        (check-pred sat? soln)
        (define v (arbitrary-concretization (evaluate tctx soln)))
        (check-pred line-transition? v)
        (check-pred line-solved? (line-transition-end v))))
    (test-case "no-hint-solved-symbolic-line"
      (parameterize-solver
        (define tctx (symbolic-line-transition 9))
        (define soln (solve (assert (= (length (line-hints (line-transition-end tctx))) 0))))
        (check-pred sat? soln)
        (define v (arbitrary-concretization (evaluate tctx soln)))
        (check-pred line-transition? v)
        (check-pred line-solved? (line-transition-end v))))
    (test-case "one-hint-solved-symbolic-line"
      (parameterize-solver
        (define tctx (symbolic-line-transition 9))
        (define soln (solve (assert (= (length (line-hints (line-transition-end tctx))) 1))))
        (check-pred sat? soln)
        (define v (arbitrary-concretization (evaluate tctx soln)))
        (check-pred line-transition? v)
        (check-pred line-solved? (line-transition-end v))))
    (test-case "max-hint-solved-symbolic-line"
      (parameterize-solver
        (define tctx (symbolic-line-transition 9))
        (define soln (solve (assert (= (length (line-hints (line-transition-end tctx))) 5))))
        (check-pred sat? soln)
        (define v (arbitrary-concretization (evaluate tctx soln)))
        (check-pred line-transition? v)
        (check-pred line-solved? (line-transition-end v))))

    (test-sym-segs 'gaps (make-line '() "------") (list (seg 0 6)))
    (test-sym-segs 'gaps (make-line '() "OOOOOO") (list (seg 0 6)))
    (test-sym-segs 'gaps (make-line '() "xxxxxxx") empty)
    (test-sym-segs 'gaps (make-line '() "-O--O-") (list (seg 0 6)))
    (test-sym-segs 'gaps (make-line '() "-O-xO-") (list (seg 0 3) (seg 4 6)))
    (test-sym-segs 'gaps (make-line '() "x-OxOO") (list (seg 1 3) (seg 4 6)))
    (test-sym-segs 'blocks (make-line '() "------") empty)
    (test-sym-segs 'blocks (make-line '() "OOOOOO") (list (seg 0 6)))
    (test-sym-segs 'blocks (make-line '() "xxxxxxx") empty)
    (test-sym-segs 'blocks (make-line '() "-O--O-") (list (seg 1 2) (seg 4 5)))
    (test-sym-segs 'blocks (make-line '() "-O-xO-") (list (seg 1 2) (seg 4 5)))
    (test-sym-segs 'blocks (make-line '() "x-OxOO") (list (seg 2 3) (seg 4 6)))

    )))

