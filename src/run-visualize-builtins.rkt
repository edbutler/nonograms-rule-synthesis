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

(define (format-builtin b)
  (define prog
    (program->stylized-html (apply-all-rewrite-rules (builtin-rule b)) (symbol->string (builtin-name b))))
  (xexp div
    (h3 ,(format "Bulitin ~a" (builtin-name b)))
    (p "Program:")
    (div ,prog)))

(define doc
  (xexp html
    ,visualization-html-header
    (body
      (h2 "Builtins")
      ,@(map format-builtin all-builtin-rules)
      )))

(write-html-to-file out-filename doc)

