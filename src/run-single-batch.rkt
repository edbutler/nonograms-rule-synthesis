
#lang rosette

(require
  "config.rkt"
  "core/core.rkt"
  "nonograms/nonograms.rkt"
  "learn/learning.rkt")

(debug-print? #t)
(load-config 'batch)
(current-parallel-worker-count 1)
(match-define (list outfile cfg items) (deserialize (read (current-input-port))))

(define start-time (current-seconds))

(define results (run-rule-learner-on-items cfg items))
(serialize-to-file
  outfile
  results)
;(for ([r results])
;  (printf "~s\n" r)))

(define end-time (current-seconds))
(print-time-delta start-time end-time)

