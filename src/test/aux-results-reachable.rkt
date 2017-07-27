#lang racket/base

; auxiliary file for testing whether a set of programs are covered by a sketch.
; used because we test these with subprocesses.
; so it reads a list of programs on stdin and puts pairs of programs, success? on stdout.

(provide run)

(require
  "../core/core.rkt"
  "../nonograms/nonograms.rkt"
  "../learn/synthesize.rkt")

(define (test-sketch-covers? features program)
  (parameterize ([current-sketch-features features])
    (sketch-covers? program (void))))

(define (run)
  (define items (deserialize (read (current-input-port))))
  (define results
    (for/list ([r items])
      (test-sketch-covers? default-program-features r)))
  (write (serialize (map cons items results))))

