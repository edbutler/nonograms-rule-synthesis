#lang racket

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "learn/solve.rkt"
  "learn/enumeration.rkt")

(debug-print? #t)
(load-config 'make-test-set)
(current-parallel-worker-count (config-ref 'num-workers))
(define outfile (config-pathref 'testing-set))

(debug-print? #t)

(define start-time (current-seconds))

(config-ref 'use-puzzles?)
(get-config)

(define result
  (cond
   [(config-ref 'use-puzzles?)
    (define num-rollouts (config-ref 'num-rollouts))
    (define puzzles (read-json-file (config-pathref 'puzzles)))
    (define boards (map json->board puzzles))
    (define all-tctx (run-board-solution-rollouts boards num-rollouts))
    (printf "size before dedup: ~a\nsize after dedup: ~a\n" (length all-tctx) (length (remove-duplicates all-tctx)))
    all-tctx]
   [else
    (define row-lengths (config-ref 'row-lengths))
    (define transitions (append-map enumerate-maximal-transitions row-lengths))
    (printf "enumerated ~a transitons.\n" (length transitions))
    transitions]))

(define end-time (current-seconds))
(printf "created ~a test items.\n" (length result))
(serialize-to-file outfile result)
(print-time-delta start-time end-time)

