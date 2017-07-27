#lang racket

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "nonograms/dsl-pretty.rkt"
  "nonograms/builtin.rkt"
  "learn/synthesize.rkt"
  "learn/enumeration.rkt"
  "learn/analysis.rkt"
  "learn/coverage.rkt"
  "learn/optimization.rkt"
  "learn/cegis.rkt"
  "learn/learning.rkt")

(debug-print? #t)
(load-config 'analyze)
(current-parallel-worker-count (config-ref 'num-workers))

(define outfile-opt (config-pathref 'optimization-results))
(define outfile-opt-pretty (config-pathref 'optimization-results-pretty))

;(define forced-rule (list-ref (deserialize-from-file "out.orig/results.rkt") 5))
;(define forced-rule2 (list-ref (deserialize-from-file "out.orig/results.rkt") 8))

(define test-set (deserialize-from-file (config-pathref 'testing-set)))

;(define test-set-proportion (/ 1 6))
;(random-seed 31904894)
;(set! test-set (take (shuffle test-set) (truncate (* (length test-set) test-set-proportion))))

(define original-trained-rules
  (append
    empty;(list forced-rule forced-rule2)
    (remove-duplicates (training-results->programs (load-training-results (config-pathref 'learning-results))))))

;(set! original-trained-rules (list
;  ;(Program
;  ;  (list (Constant 'hint 0) (Arbitrary 'hint) (Constant 'gap 0))
;  ;  (Apply '> (list (BindingValue 1) (Apply '- (list (HighestStartCell (BindingIndex 0)) (BindingIndex 2)))))
;  ;  (Fill #t (BindingIndex 2) (Apply '- (list (HighestStartCell (BindingIndex 1)) (BindingIndex 2))) (Apply '- (list (LowestEndCell (BindingIndex 1)) (Const 0)))))
;  (builtin-rule rule-cross-small-gap-left)
;  ))


(define trained-rules
  (let ([builtins (map (compose ruledata-program builtin->ruledata) all-builtin-rules)])
    (match (config-ref 'builtins)
     ["replace" builtins]
     ["ignore" original-trained-rules]
     ["augment" (append builtins original-trained-rules)])))

(printf "total trained rules: ~a\n" (length trained-rules))

(printf "loaded set: ~a\n" (config-ref 'builtins))

;(exit)

;(for ([r trained-rules])
;  (define ce (verify-program r #:counter-example-parameters (range 1 21)))
;  (when ce
;    (printf "not valid!: ~a\n  ~v ->\n~v\n" (debug-format-program r) ce (interpret/deterministic r (create-environment (line-transition-start (counter-example-input ce)))))
;    (exit)))
;    ;))

; drop redundant rules by choosing the cheapest from each cluster
(define clusters (cluster-by-coverage test-set trained-rules #:filter-subclusters? #t))
(define old-length (length trained-rules))
(set! trained-rules (map (λ (c) (argmin program-cost c)) clusters))

(printf "total distinct rules: ~a (down from ~a raw)\n" (length trained-rules) old-length)

;(define proportion-to-keep (/ 1 2))
;
;(define scores (coverage-of-individual-rules test-set trained-rules))
;
;(define to-keep
;  (take
;    (sort scores > #:key cdr)
;    (truncate (* proportion-to-keep (length scores)))))
;
;(printf "keeping ~a of ~a\n" (length to-keep) (length trained-rules))
;
;;(printf "top rules:\n")
;;(for ([r (take to-keep 10)])
;;  (displayln (debug-format-program (car r))))
;
;(set! trained-rules (map car to-keep))

;(define-values (weak-cover-bools num-weak-covered) (find-minimum-weak-cover-for-conjunctions min-core-indices 10))
;(define weak-cover-indices (filter-mapi (λ (i x) (and x i)) weak-cover-bools))
;(displayln weak-cover-indices)
;(define weak-cover (map (λ (i) (list-ref cover-list i)) weak-cover-indices))
;(define weak-cover (choose-optimal-set (remove-duplicates (map ruledata-program successes)) flat-deltas))
(define limited-cover
  (run-ruleset-optimization
    (make-optimization-parameters
      #:rules trained-rules
      #:transitions test-set
      #:max-count 10)))

(displayln limited-cover)

(serialize-to-file
  outfile-opt
  ;(map (curry list-ref trained-rules) limited-cover))
  limited-cover)

(with-output-to-file
  outfile-opt-pretty
  #:exists 'truncate
  (thunk
    (for ([prog limited-cover])
      (displayln (debug-format-program prog)))))

