#lang racket

(provide
  flag-set?
  flag-value
  get-config
  load-config
  config-ref
  config-pathref)

(require
  "core/core.rkt"
  json)

; string? -> boolean?
; #t if the given flag is in the command-line arguments
(define (flag-set? str)
  (define args (current-command-line-arguments))
  (> (vector-count (λ (s) (string=? s str)) args) 0))

; string-> (or/c false/c? string?)
(define (flag-value str)
  (define args (current-command-line-arguments))
  (define idx
    (findf
      (λ (i) (string=? (vector-ref args i) str))
      (range (vector-length args))))
  (and idx (vector-ref args (add1 idx))))

(struct config (data category))
(define global-config #f)

(define (get-config) (config-data global-config))

; symbol? -> void?
(define (load-config category)
  (define data
    (cond
     [(flag-set? "-i")
      (read-json (current-input-port))]
     [(flag-set? "-f")
      (define fname (flag-value "-f"))
      (call-with-input-file fname (λ (in) (read-json in)))]
     [else
      (define fname "config/default.json")
      (call-with-input-file fname (λ (in) (read-json in)))]))
  (set! global-config (config data category))
  ; if the root directory does not exist, create it
  (make-directory* (raw-config-ref 'files 'root-directory)))

(define (raw-config-ref category key) (hash-ref (hash-ref (config-data global-config) category) key))
(define (config-ref key #:category [category #f])
  (raw-config-ref (or category (config-category global-config)) key))

; Reference a config key from the 'files category, appending the root-dir
; symbol? -> path?
(define (config-pathref key #:category [category 'files])
  (build-path
    (raw-config-ref 'files 'root-directory)
    (raw-config-ref category key)))

