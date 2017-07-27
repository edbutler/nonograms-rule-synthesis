#lang racket

(require
  "config.rkt"
  "core/core.rkt"
  "learn/analysis.rkt"
  "learn/learning.rkt"
  "nonograms/nonograms.rkt"
  "nonograms/builtin.rkt"
  "nonograms/dsl-pretty.rkt"
  "nonograms/debug.rkt")

(define out-filename (vector-ref (current-command-line-arguments) 0))

(debug-print? #t)
(load-config 'analyze)
(current-parallel-worker-count (config-ref 'num-workers))

(define training-results (load-training-results (config-pathref 'learning-results)))

(define (format-training-result i wr)
  (define prog
    (if (work-result-success? wr) (program->stylized-html (work-result-program wr) (format "prog~a" i)) "N/A"))
  (xexp div
    (h3 ,(format "Result ~a" i))
    (p "Program:")
    (div ,prog)))

(define doc
  (xexp html
    ,visualization-html-header
    (body
      (h2 "Results")
      ,@(mapi format-training-result training-results)
      )))

(write-html-to-file out-filename doc)

