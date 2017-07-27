#lang racket

(require
  "util.rkt"
  "../core/core.rkt"
  "../nonograms/dsl-pretty.rkt"
  "../nonograms/debug.rkt"
  "../nonograms/builtin.rkt"
  "../nonograms/nonograms.rkt"
  rackunit
  rackunit/text-ui)

(define (fillt s e) (fill-action #t s e))
(define (fillf s e) (fill-action #f s e))

(define (test-expr expected expr ctx)
  (test-case (format "~a-~v" (debug-format-program expr) ctx)
    (check-true (> (program-cost expr) 0))
    (check-equal? (deserialize (serialize expr)) expr)
    (check-equal? (evaluate-expression expr ctx) expected)))

(define (test-cond expected bindings condition ctx)
  (test-case (format "~a-~v" (debug-format-program condition) ctx)
    (define prog (Program bindings condition (Fill #t C0 C0 C0)))
    (check-true (> (program-cost prog) 0))
    (check-equal? (deserialize (serialize prog)) prog)
    (define r (interpret/deterministic prog (create-environment ctx)))
    (check-equal? (and r (not (empty? r))) expected)))

(define (test-prog-impl expected prog ctx)
  (check-true (> (program-cost prog) 0))
  (check-equal? (deserialize (serialize prog)) prog)
  (check-equal? (interpret/deterministic prog (create-environment ctx)) (if expected (list expected) empty)))

(define (test-prog-impl* expected prog ctx)
  (check-true (> (program-cost prog) 0))
  (check-equal? (deserialize (serialize prog)) prog)
  (check member expected (interpret/deterministic prog (create-environment ctx))))

(define (test-prog expected prog ctx)
  (test-case (format "~a-~v" (debug-format-program prog) ctx)
    (test-prog-impl expected prog ctx)))

(void (run-tests (test-suite
  "nonograms-dsl"

  (test-expr #t (app > C3 C2) (make-line '(0) "---"))
  (test-expr #t (app > C3 C2) (make-line '(3) "OOO"))
  (test-expr #f (app > C2 C3) (make-line '(0) "---"))

  (test-expr #t (app > N C4) (make-line '(0) "-----"))
  (test-expr #f (app > N C4) (make-line '(0) "----"))
  (test-expr #t (app = N C4) (make-line '(0) "----"))
  (test-expr #t (app >= N C4) (make-line '(0) "----"))
  (test-expr #t (app >= N C4) (make-line '(0) "-----"))

  (test-expr #t (Filled? C0 #t) (make-line '(4) "O---"))
  (test-expr #f (Filled? C0 #t) (make-line '(4) "-O---"))
  (test-expr #t (Filled? C0 #f) (make-line '(4) "x---"))
  (test-expr #f (Filled? C0 #f) (make-line '(4) "-x---"))
  (test-expr #f (Filled? C5 #f) (make-line '(4) "-x--"))

  (test-cond #t
    (list (Constant 'hint 0))
    (app >= BV C4)
    (make-line '(4) "-------"))
  (test-cond #f
    (list (Constant 'hint 0))
    (app >= BV C4)
    (make-line '(1 4) "-------"))
  (test-cond #t
    (list (Constant 'hint 0))
    (app >= BV C4)
    (make-line '(4 1) "-------"))
  (test-cond #f
    (list (Constant 'hint 0))
    (app >= BV C4)
    (make-line '(3 1) "-------"))

  (test-cond #t
    (list (Constant 'gap 0))
    (app > BV C1)
    (make-line '() "--x-"))
  (test-cond #f
    (list (Constant 'gap 0))
    (app > BV C1)
    (make-line '() "-x--"))

  (let ([pmax (Max? 0)]
        [pmin (Min? 0)])
    (test-cond #t (list (Singleton 'hint)) pmax (make-line '(4) "----------"))
    (test-cond #t (list (Constant 'hint 0)) pmax (make-line '(4) "----------"))
    (test-cond #t (list (Constant 'hint 0)) pmax (make-line '(4 1) "----------"))
    (test-cond #f (list (Constant 'hint 1)) pmax (make-line '(4 1) "----------"))
    (test-cond #t (list (Constant 'hint 1)) pmax (make-line '(4 4) "----------"))
    (test-cond #f (list (Constant 'hint 0)) pmax (make-line '(1 4) "----------"))
    (test-cond #t (list (Singleton 'hint)) pmin (make-line '(4) "----------"))
    (test-cond #t (list (Constant 'hint 0)) pmin (make-line '(4) "----------"))
    (test-cond #f (list (Constant 'hint 0)) pmin (make-line '(4 1) "----------"))
    (test-cond #t (list (Constant 'hint 1)) pmin (make-line '(4 1) "----------"))
    (test-cond #t (list (Constant 'hint 1)) pmax (make-line '(4 4) "----------"))
    (test-cond #t (list (Constant 'hint 0)) pmin (make-line '(1 4) "----------"))

    (test-cond #t (list (Constant 'gap 0)) pmax (make-line '() "----x---"))
    (test-cond #t (list (Constant 'gap 0)) pmax (make-line '() "----x----"))
    (test-cond #f (list (Constant 'gap 0)) pmax (make-line '() "---x----"))

    (test-cond #t (list (Constant 'block 0)) pmax (make-line '(8) "OOOO-OOO"))
    (test-cond #t (list (Constant 'block 0)) pmax (make-line '(8) "OOO--OOO"))
    (test-cond #f (list (Constant 'block 0)) pmax (make-line '(8) "OOO-OOOO"))
    )

  (test-prog (fillt 2 4)
             (Program (list (Constant 'hint 0)) (app > (app + BV BV) N) (Fill #t C0 (app - N BV) BV))
             (make-line '(4) "------"))

  (test-prog
    (fillf 0 5)
    (program
      (Constant 'gap 0)
      (app = K C0)
      (Fill #f C0 C0 N))
    (make-line '() "-----"))

  (test-prog
    (fillt 0 4)
    (Program
      (list
        (Constant 'hint 0))
      (app = (app + (HighestStartCell BI) BV) (LowestEndCell BI))
      (Fill #t (HighestStartCell BI) C0 BV))
    (make-line '(4) "----"))

  (test-prog
    (fillf 1 2)
    (Program
      (list
        (Singleton 'hint)
        (Constant 'gap 0)
        (NoPattern))
      (app > BV SV)
      (Fill #f SI C0 SV))
    (make-line '(2) "x-x--"))

  (test-prog
    (fillt 2 4)
    (Program
      (list
        (Constant 'hint 0)
        (NoPattern)
        (Constant 'block 0)
        (Constant 'block 1))
      (app >= BV (app + FI C0))
      (Fill #t TI TV (app - FI TI)))
    (make-line '(4) "-O--O--"))

  (let ([prog
         (Program
           (list
             (Arbitrary 'hint)
             (Arbitrary 'gap))
           (And
             (Unique? 1 (app >= (BoundValue) (BindingValue 0)))
             (app = (BindingValue 0) (BindingValue 1)))
           (Fill #t (BindingIndex 1) C0 (BindingValue 1)))])
    (test-prog (fillt 4 8) prog (make-line '(4) "---x----x-"))
    (test-prog #f prog (make-line '(4) "---x----x----")))

  ;(test-prog (fillt 0 3) (Program (NoPattern) empty (And (app > H0 C0) (Filled? C0 #t)) (Fill #t C0 C0 H0)) (make-line '(3) "O----"))

  )))

(void (run-tests (test-suite
  "builtin nonograms rules"

  (for ([be all-builtin-rules])
    (match-define (builtin name prog examples) be)
    (for ([dctx examples])
      (test-case (format "built-in-~a-~a" name dctx)
        (match-define (line/fill ctx actn) dctx)
        (test-prog-impl* actn prog ctx))))

  )))

(define-simple-check (check-program-limited-to-features bool features prog)
  (equal? bool (program-limited-to-features? features prog)))

(define (test-feature-set prog features)
  (test-case (format "feature-test-~a-~a" (debug-format-program prog) features)
    (check-set=? (features-used-by-program prog) features)
    (check-program-limited-to-features #t features prog)
    (check-program-limited-to-features #f '() prog)
    (check-program-limited-to-features #t (cons 'some-bogus-feature features) prog)))

(void (run-tests (test-suite
  "program feature analysis"

  (let ([p (program (Arbitrary 'hint) (True) (Fill #t C0 C0 C1))])
    (test-feature-set p '(base hint)))

  (let ([p (program (Arbitrary 'hint) (a> C1 C0) (Fill #t C0 C0 C1))])
    (test-feature-set p '(base hint comparison)))

  (let ([p (program (Arbitrary 'hint) (True) (Fill #t C0 C0 (a+ C0 C1)))])
    (test-feature-set p '(base hint arithmetic)))

  (let ([p (program (Arbitrary 'hint) (Max? 0) (Fill #t C0 C0 C1))])
    (test-feature-set p '(base hint optimal)))

  (let ([p
         (program
           (Arbitrary 'hint)
           (Arbitrary 'gap)
           (And
             (Unique? 1 (app >= (BoundValue) (BindingValue 0)))
             (app = (BindingValue 0) (BindingValue 1)))
           (Fill #t (BindingIndex 1) C0 (BindingValue 1)))])
    (test-feature-set p '(base hint gap comparison and unique)))

  )))

