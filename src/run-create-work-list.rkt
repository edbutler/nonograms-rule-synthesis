#lang rosette

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "learn/learning.rkt")

(debug-print? #t)
(load-config 'synthesize)
(current-parallel-worker-count (config-ref 'num-workers))
(define outfile (config-pathref 'work-list))
(define transitions (deserialize-from-file (config-pathref 'training-set)))

(define fractional-subset (config-ref 'fractional-subset))

(define start-time (current-seconds))

(define generalize? (config-ref 'optimize-generalization?))
(define ce-params (config-ref 'counter-example-parameters))
(define fp-params (config-ref 'force-positive-parameters))
(define max-bindings (config-ref 'max-bindings))
(define gs-params (config-ref 'generalization-set-parameters))
(define max-sketch-depth (config-ref 'max-sketch-depth))

(define cfg
  (make-learning-config
    #:counter-example-parameters ce-params
    #:force-positive-parameters fp-params
    #:max-binding-count max-bindings
    #:generalization-set-parameters gs-params
    #:max-sketch-depth max-sketch-depth))

(define items (make-work-items transitions cfg))

(when (and (number? fractional-subset) (< fractional-subset 1))
  (set! items
    (take (shuffle items) (inexact->exact (ceiling (* fractional-subset (length items)))))))

(serialize-to-file
  outfile
  (cons cfg items))
(printf "created ~a work items\n" (length items))

(define end-time (current-seconds))
(print-time-delta start-time end-time)


