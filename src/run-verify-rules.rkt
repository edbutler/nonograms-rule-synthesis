
#lang racket

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "nonograms/dsl-pretty.rkt"
  "learn/cegis.rkt"
  "learn/synthesize.rkt"
  "learn/analysis.rkt"
  "learn/learning.rkt")

(debug-print? #t)

(debug-print? #t)
(load-config 'analyze)
(current-parallel-worker-count (config-ref 'num-workers))
(define outfile (string-append (path->string (config-pathref 'learning-results)) ".filtered"))

(define trained (load-training-results (config-pathref 'learning-results)))
(define successes (filter work-result-success? trained))

(printf "total successes: ~a\n" (length successes))

(define start-time (current-seconds))

;(set! successes (take successes 20))

(define sound (filter-unsound-rules successes))

(printf "total sound: ~a\n" (length (first sound)))

(serialize-to-file outfile sound)

(define end-time (current-seconds))

(print-time-delta start-time end-time)

