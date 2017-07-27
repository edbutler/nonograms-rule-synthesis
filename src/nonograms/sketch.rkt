#lang rosette/safe

; creating symbolic programs

(provide
  current-sketch-features
  current-max-sketch-depth
  most-specific-patterns-of-line
  build-pattern-graph
  serialize-pattern-graph
  deserialize-pattern-graph
  program-sketch)

(require
  (only-in racket match-define error local-require make-parameter set-member? parameterize)
  (for-syntax syntax/parse)
  rosette/lib/angelic
  rosette/lib/match
  "rules.rkt"
  "action.rkt"
  "ast.rkt"
  "bindings.rkt"
  "dsl-pretty.rkt"
  "interpreter.rkt"
  "../core/core.rkt")

; (parameterof (setof symbol?))
; The allowed features that can be used in program-sketch.
(define current-sketch-features (make-parameter default-program-features))
(define current-max-sketch-depth (make-parameter 2))

(define (active-feature? f) (set-member? (current-sketch-features) f))
(define (gate-feature f . lst) (if (active-feature? f) lst empty))

(define-syntax (choose-gated stx)
  (define-syntax-class element
    #:description "element"
    #:datum-literals (gate when unless)
    (pattern
      (gate feat:expr vals:expr ...)
      #:with value #'(gate-feature feat vals ...))
    (pattern
      (when condition:expr vals:expr ...)
      #:with value #'(if condition (list vals ...) empty))
    (pattern
      (unless condition:expr vals:expr ...)
      #:with value #'(if condition empty (list vals ...)))
    (pattern
      any:expr
      #:with value #'(list any)))
  (syntax-parse stx
   ;[(_ element:element ...) #'(list element.value ...)]))
   [(_ element:element ...) #'(choose element.value ...)]))

(define arithmetic-operators '(+ -))
(define comparison-operators '(= > >=))

(define (nonempty? lst) (not (empty? lst)))

(define (most-specific-patterns-of-list type lst)
  (match lst
   ['() empty]
   [(list s) (list (Singleton type))]
   [_
    (build-list/s (length lst) (λ (i) (Constant type i)))]))

(define (next-highest-patterns bnd)
  (match bnd
   [(Constant lst _) (list (Arbitrary lst))]
   [(Singleton lst) (list (Constant lst 0))]
   [_ '()]))

; creates a graph of all possible patterns climbing up the generality ladder
(define (build-pattern-graph bnd)
  (local-require racket data/queue)
  (define g (make-digraph identity))
  (define (nr b) (dg-node-ref g b))
  (define to-visit (make-queue))
  (define (visit n)
    ; for each way to increase a pattern by one level, add an edge to the graph
    (for* ([i (length n)]
           [v (next-highest-patterns (list-ref n i ))])
      (define c (list-set n i v))
      (unless (nr c)
        (enqueue! to-visit c)
        (dg-add-node! g c))
      (dg-add-edge! (nr n) (nr c) #t)))

  (dg-add-node! g bnd)
  (enqueue! to-visit bnd)
  (let loop ()
    (cond
     [(queue-empty? to-visit) g]
     [else
      (visit (dequeue! to-visit))
      (loop)])))

(define (serialize-pattern-graph grph)
  (serialize-digraph serialize identity grph))

(define (deserialize-pattern-graph grph)
  (deserialize-digraph identity deserialize identity grph))

; Other parts of the code rely on this returning patterns in a consistent order.
(define (most-specific-patterns-of-line ctx)
  (define (add feature fn)
    (if (active-feature? feature)
        (most-specific-patterns-of-list feature (fn ctx))
        empty))
  (append
    (add feature-hint line-hints)
    (add feature-gap gaps-of-line)
    (add feature-block blocks-of-line)))

(define banned-pattern-id (make-parameter #f))

; (listof symbol?), (or/c false? line?), (listof pattern?) -> Program?
; TODO main-ctx is currently unused, remove is possible
(define (program-sketch _ main-ctx patterns)

  (define hint-patterns
    (filter
      (λ (i)
        (and (ListPattern? (list-ref patterns i)) (equal? (ListPattern-type (list-ref patterns i)) 'hint)))
      (range/s 0 (length patterns))))
  (define non-hint-patterns
    (filter
      (λ (i)
        (and (ListPattern? (list-ref patterns i)) (not (equal? (ListPattern-type (list-ref patterns i)) 'hint))))
      (range/s 0 (length patterns))))

  (define (index-sketch possible)
    (define pats
      (cond
       [(banned-pattern-id)
        (filter-not (λ (x) (= x (banned-pattern-id))) possible)]
       [else possible]))
    (choose pats))

  (define (filter-banned-index possible)
    (cond
     [(banned-pattern-id)
      (filter-not (λ (x) (= x (banned-pattern-id))) possible)]
     [else possible]))

  (define (all-pattern-indices)
    (filter-banned-index (range/s 0 (length patterns))))
  (define (hint-pattern-indices)
    (filter-banned-index hint-patterns))
  (define (non-hint-pattern-indices)
    (filter-banned-index non-hint-patterns))

  (define (pattern-indices-of type)
    (filter
      (λ (i) (and (ListPattern? (list-ref patterns i)) (equal? (ListPattern-type (list-ref patterns i)) type)))
      (all-pattern-indices)))

  (define pattern-types (list 'hint 'block 'gap))

  ; whether a given pattern index is viable for the Unique? construct
  (define (can-support-unique? i)
    (define p (list-ref patterns i))
    ; can use it anytime it is not a Singleton (because those are unique by definition)
    (and (ListPattern? p) (not (Singleton? p))))

  ; integer representing a delta, length, etc.
  (define (delta-expr-sketch depth)
    (define (base-delta-expr-sketch)
      (choose-gated
        (Const (??* -1 2))
        (gate feature-line-length (Ident 'N))
        (gate feature-hint-length (Ident 'K))
        ; only choose this if we currently have banned a value (and thus are in a Unique? construct)
        (when (banned-pattern-id) (BoundValue))
        (unless (empty? (all-pattern-indices))
          (BindingValue (choose (all-pattern-indices))))))

    (define s1d (sub1 depth))
    (if (= 0 depth)
        (base-delta-expr-sketch)
        (let ([d1 (delta-expr-sketch s1d)]
              [d2 (delta-expr-sketch s1d)]
              [p1 (point-expr-sketch s1d)]
              [p2 (point-expr-sketch s1d)])
          (choose-gated
            d1
            (gate feature-arithmetic
                  (Apply (choose arithmetic-operators) (list d1 d2))
                  (Apply '- (list p1 p2)))))))

  ; integer representing an index, position, etc.
  (define (point-expr-sketch depth)
    (define (base-point-expr-sketch)
      (choose-gated
        (Const (??))
        (unless (empty? (non-hint-pattern-indices)) (BindingIndex (choose (non-hint-pattern-indices))))
        (when (and (nonempty? (hint-pattern-indices)) (active-feature? feature-geometry))
              (LowestEndCell (BindingIndex (choose (hint-pattern-indices))))
              (HighestStartCell (BindingIndex (choose (hint-pattern-indices)))))))

    (define s1d (sub1 depth))
    (if (= 0 depth)
        (base-point-expr-sketch)
        (let ([p (point-expr-sketch s1d)]
              [d (delta-expr-sketch s1d)])
          (choose-gated
            p
            (gate feature-arithmetic
                  (Apply (choose arithmetic-operators) (list p d)))))))

  (define (length-expr-sketch depth)
    ;(choose* (Ident 'K) (Ident 'G) (Ident 'B) (Const (??))))
    (Const (??)))

  (define (condition-sketch depth)
    (define (term d)
      (define s1d (sub1 d))
      (define p1 (point-expr-sketch s1d))
      (define p2 (point-expr-sketch s1d))
      (define d1 (delta-expr-sketch s1d))
      (define d2 (delta-expr-sketch s1d))
      (define l1 (length-expr-sketch s1d))
      (define l2 (length-expr-sketch s1d))
      (choose-gated
        (True)
        (gate feature-filled (Filled? p1 (!!* val)))
        (gate feature-comparison
          (Apply
            (choose comparison-operators)
            (choose*
              (list p1 p2)
              (list d1 d2)
              (list l1 l2))))))

    (define sub-part (term depth))
    (define sub
      (choose-gated
        sub-part
        (when (and (active-feature? feature-optimal) (nonempty? (all-pattern-indices)))
              (Max? (choose (all-pattern-indices)))
              (Min? (choose (all-pattern-indices))))
        (when (and (active-feature? feature-unique) (nonempty? (filter can-support-unique? (all-pattern-indices))))
              (let ([indices (filter can-support-unique? (all-pattern-indices))])
                (choose
                  (map
                    (λ (idx)
                      (parameterize ([banned-pattern-id idx])
                        (Unique? idx (term depth))))
                    indices))))))

    (choose-gated
      (True)
      (gate feature-and
            (And sub (term (sub1 depth)))
            (And sub (And (term (sub1 depth)) (term (sub1 depth)))))
      sub))

  (define (action-sketch depth)
    (define d (sub1 depth))
    (choose*
      (Fill
        (!!* value)
        (point-expr-sketch d)
        (delta-expr-sketch d)
        (delta-expr-sketch d))
      (Fill
        (!!* value)
        C0
        (point-expr-sketch d)
        (point-expr-sketch d))))

  (define max-depth (current-max-sketch-depth))
  (Program patterns (condition-sketch max-depth) (action-sketch max-depth)))

