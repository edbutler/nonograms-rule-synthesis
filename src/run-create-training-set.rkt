#lang racket

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "learn/enumeration.rkt")

(debug-print? #t)
(load-config 'make-training-set)
(current-parallel-worker-count (config-ref 'num-workers))
(define row-lengths (config-ref 'row-lengths))
(define fractional-subset (config-ref 'fractional-subset))
(define outfile (config-pathref 'training-set))

(define start-time (current-seconds))
(define result (append-map (λ (l) (enumerate-maximal-transitions l #:canonical-only? (config-ref 'canonical-only?))) row-lengths))
(define end-time (current-seconds))
(printf "enumerated ~a transitons.\n" (length result))
(when (and (number? fractional-subset) (< fractional-subset 1))
  (set! result
    (take (shuffle result) (inexact->exact (ceiling (* fractional-subset (length result)))))))
(printf "storing ~a transitons.\n" (length result))

(for ([t (take* result 10)])
  (printf "~v\n" t))

(print-time-delta start-time end-time)
(serialize-to-file outfile result)


