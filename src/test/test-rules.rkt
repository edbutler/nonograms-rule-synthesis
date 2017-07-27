#lang racket

(require
  rackunit rackunit/text-ui
  "../nonograms/nonograms.rkt"
  "../nonograms/debug.rkt")

(define (test-solved ctx expected)
  (test-case (format "solved-~a" ctx)
    (define pred (if expected line-solved? (compose not line-solved?)))
    (check-pred pred ctx)))

(define (test-compatible expected ctx1 ctx2)
  (test-case (format "compatible-~a-~a" ctx1 ctx2)
    (check-equal? (line-weaker? ctx1 ctx2) expected)))

(define (test-compatible* expected tctx actn)
  (test-case (format "compatible-~a-~a" tctx actn)
    (check-equal? (action-compatible-with-transition? actn tctx) expected)))

(define (test-segments expected ctx segments)
  (test-case (format "segments-~v-~v" ctx segments)
    (check-equal? (segments-consistent? segments (line-cells ctx)) expected)))

(define (test-gaps ctx expected)
  (test-case (format "gaps-~v" ctx))
  (check-equal? (gaps-of-line ctx) expected))

(define (test-blocks ctx expected)
  (test-case (format "blocks-~v" ctx))
  (check-equal? (blocks-of-line ctx) expected))

;(define (test-impact sz dctx)
;  (test-case (format "impact-~v-~a" dctx sz)
;    (check-equal? (line-delta-impact dctx) sz)))

(define (fillt s e) (fill-action #t s e))
(define (fillf s e) (fill-action #f s e))
(define (seg s e) (segment s e #t))

(void (run-tests (test-suite
  "nonograms-line-rules"

  (test-solved (make-line '(0) "xxx") #t)
  (test-solved (make-line '(1) "xxx") #f)
  (test-solved (make-line '(1) "---") #f)
  (test-solved (make-line '(1) "Ox-") #f)
  (test-solved (make-line '(1) "-xO") #f)
  (test-solved (make-line '(1) "-O-") #f)
  (test-solved (make-line '(1) "xOx") #t)
  (test-solved (make-line '(1) "x-x") #f)
  (test-solved (make-line '(4 5) "OOOOxOOOOO") #t)
  (test-solved (make-line '(5 4) "OOOOxOOOOO") #f)
  (test-solved (make-line '(2 1 2 2) "OOxOxOOxOO") #t)
  (test-solved (make-line '(2 1 2 2) "OOxOxOOx-O") #f)
  (test-solved (make-line '(2 1 1 2) "OOxOxOOxOO") #f)

  (test-compatible #t
    (make-line '(1 2) "----")
    (make-line '(1 2) "OxOO"))
  (test-compatible #f
    (make-line '(1 2) "OxOO")
    (make-line '(1 2) "----"))
  (test-compatible #t
    (make-line '(1 2) "OxOO")
    (make-line '(1 2) "OxOO"))
  (test-compatible #f
    (make-line '(2 1) "----")
    (make-line '(1 2) "OxOO"))
  (test-compatible #t
    (make-line '(3) "x-O--")
    (make-line '(3) "xxOOO"))
  (test-compatible #t
    (make-line '(3) "-xOOO")
    (make-line '(3) "xxOOO"))

  (test-compatible* #t (make-transition '(1 2) "----" "OxOO") (fillt 0 1))
  (test-compatible* #f (make-transition '(1 2) "----" "OxOO") (fillt 0 2))
  (test-compatible* #t (make-transition '(1 2) "----" "OxOO") (fillt 2 4))
  (test-compatible* #f (make-transition '(1 2) "----" "OxOO") (fillt 3 5))

  (test-segments #t (make-line '() "xx") (list))
  (test-segments #f (make-line '() "OO") (list))
  (test-segments #f (make-line '() "--") (list))
  (test-segments #t (make-line '(2) "OO") (list (segment 0 2 #t)))
  (test-segments #f (make-line '(2) "xx") (list (segment 0 2 #t)))
  (test-segments #t (make-line '(2) "xx") (list (segment 0 2 #f)))
  (test-segments #t (make-line '(1) "Oxxxx") (list (segment 0 2 #f) (segment 1 3 #f) (segment 0 1 #t)))

  (test-gaps (make-line '() "------") (list (seg 0 6)))
  (test-gaps (make-line '() "OOOOOO") (list (seg 0 6)))
  (test-gaps (make-line '() "xxxxxxx") empty)
  (test-gaps (make-line '() "-O--O-") (list (seg 0 6)))
  (test-gaps (make-line '() "-O-xO-") (list (seg 0 3) (seg 4 6)))
  (test-gaps (make-line '() "x-OxOO") (list (seg 1 3) (seg 4 6)))

  (test-blocks (make-line '() "------") empty)
  (test-blocks (make-line '() "OOOOOO") (list (seg 0 6)))
  (test-blocks (make-line '() "xxxxxxx") empty)
  (test-blocks (make-line '() "-O--O-") (list (seg 1 2) (seg 4 5)))
  (test-blocks (make-line '() "-O-xO-") (list (seg 1 2) (seg 4 5)))
  (test-blocks (make-line '() "x-OxOO") (list (seg 2 3) (seg 4 6)))

  ;(test-impact 0 (make-delta '() "-----" #t 0 0))
  ;(test-impact 3 (make-delta '() "-----" #t 1 4))
  ;(test-impact 0 (make-delta '() "OOOOO" #t 1 4))
  ;(test-impact 1 (make-delta '() "OO-OO" #t 1 4))

  )))

;(void (run-tests (test-suite
;  "nonograms-board-rules"

  ;(let ([brd (make-empty-board '((2)(3)(4)) '((1)(2)(3)(3)))])
  ;  (test-case "board sanity"
  ;    (check-equal? (board-width brd) 4)
  ;    (check-equal? (board-height brd) 3)
  ;    (check-false (board-solved? brd))
  ;    (check-true (board-partial? brd))
  ;    (check-false (board-filled? brd))

  ;    (board-set! brd 0 0 #f)
  ;    (board-set! brd 1 0 #f)
  ;    (board-set! brd 2 0 #t)
  ;    (board-set! brd 3 0 #t)
  ;    (board-set! brd 0 1 #f)
  ;    (board-set! brd 1 1 #t)
  ;    (board-set! brd 2 1 #t)
  ;    (board-set! brd 3 1 #t)
  ;    (board-set! brd 0 2 #t)
  ;    (board-set! brd 1 2 #t)
  ;    (board-set! brd 2 2 #t)
  ;    (board-set! brd 3 2 #t)

  ;    (check-true (board-solved? brd))
  ;    (check-true (board-filled? brd))
  ;    (check-false (board-partial? brd))
  ;    ))

;  )))
