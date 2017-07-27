#lang rosette

(require
  rackunit rackunit/text-ui
  "../core/core.rkt"
  "../learn/synthesize.rkt"
  "../learn/cegis.rkt"
  "../nonograms/nonograms.rkt"
  "../nonograms/dsl-pretty.rkt"
  "../nonograms/debug.rkt")

(void (run-tests (test-suite
  "nonograms-synthesis"

  (test-case "uncovered example"
    (define dctx (make-line/fill '(4) "------" #t 2 4))
    (define prog
      (Program
        (list
          (Arbitrary 'hint))
        (app > (app + (BindingValue 0) (BindingValue 0)) (app + N C1))
        (Fill #t C0 (app - N (BindingValue 0)) (BindingValue 0)))
      )
    (define prog2
      (Program
        (list
          (Arbitrary 'hint))
        (app > (app + (BindingValue 0) (BindingValue 0)) N)
        (Fill #t C0 (app - N (BindingValue 0)) (BindingValue 0)))
      )
    (check-true (not (not (interpret/deterministic prog (create-environment (line/fill-line dctx))))))
    (define ce-params '(2 5 6 10 15))
    (define ce
      (use-verifiers ([vfrs ce-params])
        (find-program-uncovered-example vfrs prog (list prog2) (list 0))))
    (check-true (not (not ce)))
    (define ce*
      (use-verifiers ([vfrs ce-params])
        (find-program-uncovered-example vfrs prog (list prog) (list 0))))
    (check-true (not ce*))
    )


  )))

