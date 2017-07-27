#lang racket

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "nonograms/builtin.rkt"
  "nonograms/dsl-pretty.rkt"
  "nonograms/debug.rkt")

(load-config 'analyze)
(define out-filename (vector-ref (current-command-line-arguments) 0))
(define rules (deserialize-from-file (config-pathref 'optimization-results)))

(define (format-result i r)
  (define prog
    (program->stylized-html (apply-all-rewrite-rules r) (format "prog~a" i)))
  (xexp div
    (h3 ,(format "Result ~a" i))
    (p "Program:")
    (div ,prog)))

(define doc
  (xexp html
    ,visualization-html-header
    (body
      (h2 "Optimal Rules")
      ,@(mapi format-result rules)
      )))

(write-html-to-file out-filename doc)

