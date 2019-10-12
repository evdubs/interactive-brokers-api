#lang racket/base

(require racket/contract
         racket/list
         racket/match
         racket/string
         srfi/19
         "base-structs.rkt")

(provide
 (contract-out
  [struct contract-details-rsp
    ((request-id integer?)
     (symbol string?)
     (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                          'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f))
     (expiry (or/c date? #f))
     (strike (or/c rational? #f))
     (right (or/c 'call 'put #f))
     (exchange string?)
     (currency string?)
     (local-symbol string?)
     (market-name string?)
     (trading-class string?)
     (contract-id integer?)
     (minimum-tick-increment rational?)
     (multiplier string?)
     (order-types (listof string?))
     (valid-exchanges (listof string?))
     (price-magnifier integer?)
     (underlying-contract-id integer?)
     (long-name string?)
     (primary-exchange string?)
     (contract-month string?)
     (industry string?)
     (category string?)
     (subcategory string?)
     (time-zone-id string?)
     (trading-hours (listof string?))
     (liquid-hours (listof string?))
     (ev-rule string?)
     (ev-multiplier string?))]
  [struct err-rsp
    ((id integer?)
     (error-code integer?)
     (error-msg string?))]
  [struct execution-rsp
    ((request-id integer?)
     (order-id integer?)
     (contract-id integer?)
     (symbol string?)
     (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                          'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f))
     (expiry (or/c date? #f))
     (strike (or/c rational? #f))
     (right (or/c 'call 'put #f))
     (multiplier (or/c rational? #f))
     (exchange string?)
     (currency string?)
     (local-symbol string?)
     (trading-class string?)
     (execution-id string?)
     (timestamp date?)
     (account string?)
     (executing-exchange string?)
     (side string?)
     (shares rational?)
     (price rational?)
     (perm-id integer?)
     (client-id integer?)
     (liquidation integer?)
     (cumulative-quantity integer?)
     (average-price rational?)
     (order-reference string?)
     (ev-rule string?)
     (ev-multiplier rational?)
     (model-code string?))]
  [struct next-valid-id-rsp
    ((order-id integer?))]
  [struct open-order-rsp
    ((order-id integer?)
     (contract-id integer?)
     (symbol string?)
     (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                          'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f))
     (expiry (or/c date? #f))
     (strike (or/c rational? #f))
     (right (or/c 'call 'put #f))
     (multiplier (or/c rational? #f))
     (exchange string?)
     (currency string?)
     (local-symbol string?)
     (trading-class string?)
     (action (or/c 'buy 'sell 'sshort))
     (total-quantity rational?)
     (order-type string?)
     (limit-price (or/c rational? #f))
     (aux-price (or/c rational? #f))
     (time-in-force (or/c 'day 'gtc 'opg 'ioc 'gtd 'gtt 'auc 'fok 'gtx 'dtc))
     (oca-group string?)
     (account string?)
     (open-close (or/c 'open 'close #f))
     (origin (or/c 'customer 'firm))
     (order-ref string?)
     (client-id integer?) ; new
     (perm-id integer?) ; new
     (outside-rth boolean?)
     (hidden boolean?)
     (discretionary-amount (or/c rational? #f))
     (good-after-time (or/c date? #f))
     (advisor-group string?)
     (advisor-method string?)
     (advisor-percentage string?)
     (advisor-profile string?)
     (model-code string?)
     (good-till-date (or/c date? #f))
     (rule-80-a string?)
     (percent-offset (or/c rational? #f))
     (settling-firm string?)
     (short-sale-slot (or/c 0 1 2))
     (designated-location string?)
     (exempt-code integer?)
     (auction-strategy (or/c 'match 'improvement 'transparent #f))
     (starting-price (or/c rational? #f))
     (stock-ref-price (or/c rational? #f))
     (delta (or/c rational? #f))
     (stock-range-lower (or/c rational? #f))
     (stock-range-upper (or/c rational? #f))
     (display-size (or/c integer? #f))
     (block-order boolean?)
     (sweep-to-fill boolean?)
     (all-or-none boolean?)
     (minimum-quantity (or/c integer? #f))
     (oca-type integer?)
     (electronic-trade-only boolean?)
     (firm-quote-only boolean?)
     (nbbo-price-cap (or/c rational? #f))
     (parent-id integer?)
     (trigger-method integer?)
     (volatility (or/c rational? #f))
     (volatility-type (or/c integer? #f))
     (delta-neutral-order-type string?)
     (delta-neutral-aux-price (or/c rational? #f))
     (delta-neutral-contract-id (or/c integer? #f))
     (delta-neutral-settling-firm string?)
     (delta-neutral-clearing-account string?)
     (delta-neutral-clearing-intent string?)
     (delta-neutral-open-close (or/c 'open 'close #f))
     (delta-neutral-short-sale boolean?)
     (delta-neutral-short-sale-slot (or/c integer? #f))
     (delta-neutral-designated-location string?)
     (continuous-update integer?)
     (reference-price-type (or/c integer? #f))
     (trailing-stop-price (or/c rational? #f))
     (trailing-percent (or/c rational? #f))
     (basis-points (or/c rational? #f))
     (basis-points-type (or/c integer? #f))
     (combo-legs (listof combo-leg?))
     (order-combo-legs (listof rational?))
     (smart-combo-routing-params hash?)
     (scale-init-level-size (or/c integer? #f))
     (scale-subs-level-size (or/c integer? #f))
     (scale-price-increment (or/c rational? #f))
     (scale-price-adjust-value (or/c rational? #f))
     (scale-price-adjust-interval (or/c integer? #f))
     (scale-profit-offset (or/c rational? #f))
     (scale-auto-reset boolean?)
     (scale-init-position (or/c integer? #f))
     (scale-init-fill-quantity (or/c integer? #f))
     (scale-random-percent boolean?)
     (hedge-type string?)
     (hedge-param string?)
     (opt-out-smart-routing boolean?)
     (clearing-account string?)
     (clearing-intent (or/c 'ib 'away 'pta #f))
     (not-held boolean?)
     (delta-neutral-underlying-contract-id (or/c integer? #f))
     (delta-neutral-underlying-delta (or/c rational? #f))
     (delta-neutral-underlying-price (or/c rational? #f))
     (algo-strategy string?)
     (algo-strategy-params (listof string?))
     (solicited boolean?)
     (what-if boolean?)
     (status string?)
     (initial-margin (or/c rational? #f))
     (maintenance-margin (or/c rational? #f))
     (equity-with-loan (or/c rational? #f))
     (commission (or/c rational? #f))
     (minimum-commission (or/c rational? #f))
     (maximum-commission (or/c rational? #f))
     (commission-currency string?)
     (warning-text string?)
     (randomize-size boolean?)
     (randomize-price boolean?)
     (reference-contract-id (or/c integer? #f))
     (is-pegged-change-amount-decrease boolean?)
     (pegged-change-amount (or/c rational? #f))
     (reference-change-amount (or/c rational? #f))
     (reference-exchange-id string?)
     (conditions list?)
     (adjusted-order-type (or/c 'mkt 'lmt 'stp 'stp-limit 'rel 'trail 'box-top 'fix-pegged 'lit 'lmt-+-mkt
                                'loc 'mit 'mkt-prt 'moc 'mtl 'passv-rel 'peg-bench 'peg-mid 'peg-mkt 'peg-prim
                                'peg-stk 'rel-+-lmt 'rel-+-mkt 'snap-mid 'snap-mkt 'snap-prim 'stp-prt
                                'trail-limit 'trail-lit 'trail-lmt-+-mkt 'trail-mit 'trail-rel-+-mkt 'vol
                                'vwap 'quote 'ppv 'pdv 'pmv 'psv #f))
     (trigger-price (or/c rational? #f))
     (trail-stop-price (or/c rational? #f))
     (limit-price-offset (or/c rational? #f))
     (adjusted-stop-price (or/c rational? #f))
     (adjusted-stop-limit-price (or/c rational? #f))
     (adjusted-trailing-amount (or/c rational? #f))
     (adjusted-trailing-unit integer?)
     (soft-dollar-tier-name string?)
     (soft-dollar-tier-value string?)
     (soft-dollar-tier-display-name string?))])
 parse-msg)

(struct contract-details-rsp
  (request-id
   symbol
   security-type
   expiry
   strike
   right
   exchange
   currency
   local-symbol
   market-name
   trading-class
   contract-id
   minimum-tick-increment
   multiplier
   order-types
   valid-exchanges
   price-magnifier
   underlying-contract-id
   long-name
   primary-exchange
   contract-month
   industry
   category
   subcategory
   time-zone-id
   trading-hours
   liquid-hours
   ev-rule
   ev-multiplier
   ; need some handling for sec-id-list
   )
  #:transparent)

(struct err-rsp
  (id
   error-code
   error-msg)
  #:transparent)

(struct execution-rsp
  (request-id 
   order-id
   contract-id
   symbol
   security-type
   expiry
   strike
   right
   multiplier
   exchange
   currency
   local-symbol
   trading-class
   execution-id
   timestamp
   account
   executing-exchange
   side
   shares
   price
   perm-id
   client-id
   liquidation
   cumulative-quantity
   average-price
   order-reference
   ev-rule
   ev-multiplier
   model-code)
  #:transparent)

(struct next-valid-id-rsp
  (order-id)
  #:transparent)

(struct open-order-rsp
  (order-id
   contract-id
   symbol
   security-type
   expiry
   strike
   right
   multiplier
   exchange
   currency
   local-symbol
   trading-class
   action
   total-quantity
   order-type
   limit-price
   aux-price
   time-in-force
   oca-group
   account
   open-close
   origin
   order-ref
   client-id ; new
   perm-id ; new
   outside-rth
   hidden
   discretionary-amount
   good-after-time
   advisor-group
   advisor-method
   advisor-percentage
   advisor-profile
   model-code
   good-till-date
   rule-80-a
   percent-offset
   settling-firm
   short-sale-slot
   designated-location
   exempt-code
   auction-strategy
   starting-price
   stock-ref-price
   delta
   stock-range-lower
   stock-range-upper
   display-size
   block-order
   sweep-to-fill
   all-or-none
   minimum-quantity
   oca-type
   electronic-trade-only
   firm-quote-only
   nbbo-price-cap
   parent-id
   trigger-method
   volatility
   volatility-type
   delta-neutral-order-type
   delta-neutral-aux-price
   delta-neutral-contract-id
   delta-neutral-settling-firm
   delta-neutral-clearing-account
   delta-neutral-clearing-intent
   delta-neutral-open-close
   delta-neutral-short-sale
   delta-neutral-short-sale-slot
   delta-neutral-designated-location
   continuous-update
   reference-price-type
   trailing-stop-price
   trailing-percent
   basis-points
   basis-points-type
   combo-legs
   order-combo-legs
   smart-combo-routing-params
   scale-init-level-size
   scale-subs-level-size
   scale-price-increment
   scale-price-adjust-value
   scale-price-adjust-interval
   scale-profit-offset
   scale-auto-reset
   scale-init-position
   scale-init-fill-quantity
   scale-random-percent
   hedge-type
   hedge-param
   opt-out-smart-routing
   clearing-account
   clearing-intent
   not-held
   delta-neutral-underlying-contract-id
   delta-neutral-underlying-delta
   delta-neutral-underlying-price
   algo-strategy
   algo-strategy-params
   solicited
   what-if
   status
   initial-margin
   maintenance-margin
   equity-with-loan
   commission
   minimum-commission
   maximum-commission
   commission-currency
   warning-text
   randomize-size
   randomize-price
   reference-contract-id
   is-pegged-change-amount-decrease
   pegged-change-amount
   reference-change-amount
   reference-exchange-id
   conditions
   adjusted-order-type
   trigger-price
   trail-stop-price
   limit-price-offset
   adjusted-stop-price
   adjusted-stop-limit-price
   adjusted-trailing-amount
   adjusted-trailing-unit
   soft-dollar-tier-name
   soft-dollar-tier-value
   soft-dollar-tier-display-name)
  #:transparent)

; ensure string->number conversions try to exactly represent the provided decimal
(read-decimal-as-inexact #f)

; convert a byte string message received over the wire to the appropriate structure
(define/contract (parse-msg str)
  (-> bytes? (or/c contract-details-rsp?
                   date?
                   err-rsp?
                   execution-rsp?
                   (listof string?)
                   next-valid-id-rsp?
                   open-order-rsp?))
  (match (string-split (bytes->string/utf-8 str) "\0")
    ; generic error message
    ; ignoring error responses with version < 2
    [(list "4" "2" id error-code message) (err-rsp (string->number id) (string->number error-code) message)]
    ; open order
    [(list-rest "5" version details)
     (let* ([combo-legs-index 78]
            [combo-legs-size (string->number (list-ref details combo-legs-index))]
            [order-combo-legs-index (+ 1 combo-legs-index (* 8 combo-legs-size))]
            [order-combo-legs-size (string->number (list-ref details order-combo-legs-index))]
            [smart-combo-routing-params-index (+ 1 order-combo-legs-index order-combo-legs-size)]
            [smart-combo-routing-params-size (string->number (list-ref details smart-combo-routing-params-index))]
            [scale-init-level-size-index (+ 1 smart-combo-routing-params-index (* 2 smart-combo-routing-params-size))]
            [hedge-type-index (if (equal? "" (list-ref details (+ scale-init-level-size-index 2)))
                                  (+ scale-init-level-size-index 3)
                                  (+ scale-init-level-size-index 10))]
            [opt-out-smart-routing-index (if (equal? "" (list-ref details hedge-type-index))
                                             (+ hedge-type-index 1)
                                             (+ hedge-type-index 2))]
            [delta-neutral-contract-indicator (string->number (list-ref details (+ 4 opt-out-smart-routing-index)))]
            [algo-strategy-index (if (equal? 0 delta-neutral-contract-indicator)
                                     (+ opt-out-smart-routing-index 5)
                                     (+ opt-out-smart-routing-index 9))]
            [algo-params-size (if (equal? "" (list-ref details algo-strategy-index))
                                  0
                                  (string->number (list-ref details (+ 1 algo-strategy-index))))]
            [solicited-index (+ 1 algo-strategy-index (if (< 0 algo-params-size) 1 0) (* 2 algo-params-size))]
            [conditions-index (if (equal? "PEG BENCH" (list-ref details 14))
                                  (+ 18 solicited-index)
                                  (+ 13 solicited-index))]
            [conditions-size (string->number (list-ref details conditions-index))]
            [adjusted-order-type-index (+ 1 conditions-index (if (< 0 conditions-size) 2 0) conditions-size)])
       (open-order-rsp
        (string->number (list-ref details 0)) ; order-id
        (string->number (list-ref details 1)) ; contract-id
        (list-ref details 2) ; symbol
        (string->symbol (string-downcase (list-ref details 3))) ; security-type
        (if (equal? "" (list-ref details 4))
            #f (string->date (list-ref details 4) "~Y~m~d")) ; expiry
        (string->number (list-ref details 5)) ; strike
        (match (list-ref details 6)
          ["C" 'call]
          ["P" 'put]
          [_ #f]) ; right
        (string->number (list-ref details 7)) ; multiplier
        (list-ref details 8) ; exchange
        (list-ref details 9) ; currency
        (list-ref details 10) ; local-symbol
        (list-ref details 11) ; trading-class
        (string->symbol (string-downcase (list-ref details 12))) ; action
        (string->number (list-ref details 13)) ; total-quantity
        (list-ref details 14) ; order-type
        (string->number (list-ref details 15)) ; limit-price
        (string->number (list-ref details 16)) ; aux-price
        (string->symbol (string-downcase (list-ref details 17))) ; time-in-force
        (list-ref details 18) ; oca-group
        (list-ref details 19) ; account
        (match (list-ref details 20)
          ["O" 'open]
          ["C" 'close]
          [_ #f]) ; open-close
        (match (list-ref details 21)
          ["0" 'customer]
          ["1" 'firm]) ; origin
        (list-ref details 22) ; order-ref
        (string->number (list-ref details 23)) ; client-id
        (string->number (list-ref details 24)) ; perm-id
        (if (equal? "1" (list-ref details 25)) #t #f) ; outside-rth
        (if (equal? "1" (list-ref details 26)) #t #f) ; hidden
        (string->number (list-ref details 27)) ; discretionary-amount
        ; take out the time-zone-name as srfi/19 does not handle this. assume local time zone
        (if (equal? "" (list-ref details 28))
            #f (string->date (first (regexp-match #px"([0-9]{8} [0-9]{2}:[0-9]{2}:[0-9]{2}) [A-Z]+"
                                                  (list-ref details 28))) "~Y~m~d ~H:~M:~S")) ; good-after-time
        ; deprecated shares allocation
        (list-ref details 30) ; advisor-group
        (list-ref details 31) ; advisor-method
        (list-ref details 32) ; advisor-percentage
        (list-ref details 33) ; advisor-profile
        (list-ref details 34) ; model-code
        (if (equal? "" (list-ref details 35))
            #f (string->date (list-ref details 35) "~Y~m~d")) ; good-till-date
        (list-ref details 36) ; rule-80-a
        (string->number (list-ref details 37)) ; percent-offset
        (list-ref details 38) ; settling-firm
        (string->number (list-ref details 39)) ; short-sale-slot
        (list-ref details 40) ; designated-location
        (string->number (list-ref details 41)) ; exempt-code
        (match (list-ref details 42)
          ["1" 'match]
          ["2" 'improvement]
          ["3" 'transparent]
          [_ #f]) ; auction-strategy
        (string->number (list-ref details 43)) ; starting-price
        (string->number (list-ref details 44)) ; stock-ref-price
        (string->number (list-ref details 45)) ; delta
        (string->number (list-ref details 46)) ; stock-range-lower
        (string->number (list-ref details 47)) ; stock-range-upper
        (string->number (list-ref details 48)) ; display-size
        (if (equal? "1" (list-ref details 49)) #t #f) ; block-order
        (if (equal? "1" (list-ref details 50)) #t #f) ; sweep-to-fill
        (if (equal? "1" (list-ref details 51)) #t #f) ; all-or-none
        (string->number (list-ref details 52)) ; minimum-quantity
        (string->number (list-ref details 53)) ; oca-type
        (if (equal? "1" (list-ref details 54)) #t #f) ; electronic-trade-only
        (if (equal? "1" (list-ref details 55)) #t #f) ; firm-quote-only
        (string->number (list-ref details 56)) ; nbbo-price-cap
        (string->number (list-ref details 57)) ; parent-id
        (string->number (list-ref details 58)) ; trigger-method
        (string->number (list-ref details 59)) ; volatility
        (string->number (list-ref details 60)) ; volatility-type
        (list-ref details 61) ; delta-neutral-order-type
        (string->number (list-ref details 62)) ; delta-neutral-aux-price
        (string->number (list-ref details 63)) ; delta-neutral-contract-id
        (list-ref details 64) ; delta-neutral-settling-firm
        (list-ref details 65) ; delta-neutral-clearing-account
        (list-ref details 66) ; delta-neutral-clearing-intent
        (match (list-ref details 67)
          ["O" 'open]
          ["C" 'close]
          [_ #f]) ; delta-neutral-open-close
        (if (equal? "1" (list-ref details 68)) #t #f) ; delta-neutral-short-sale
        (string->number (list-ref details 69)) ; delta-neutral-short-sale-slot
        (list-ref details 70) ; delta-neutral-designated-location
        (string->number (list-ref details 71)) ; continuous-update
        (string->number (list-ref details 72)) ; reference-price-type
        (string->number (list-ref details 73)) ; trailing-stop-price
        (string->number (list-ref details 74)) ; trailing-percent
        (string->number (list-ref details 75)) ; basis-points
        (string->number (list-ref details 76)) ; basis-points-type
        (map (λ (i) (combo-leg
                     (string->number (list-ref details (+ 1 (* i 8) combo-legs-index))) ; contract-id
                     (string->number (list-ref details (+ 2 (* i 8) combo-legs-index))) ; ratio
                     (string->symbol (string-downcase (list-ref details (+ 3 (* i 8) combo-legs-index)))) ; action
                     (list-ref details (+ 4 (* i 8) combo-legs-index)) ; exchange
                     (match (list-ref details (+ 5 (* i 8) combo-legs-index))
                       ["0" 'same]
                       ["1" 'open]
                       ["2" 'close]
                       [_ #f]) ; open-close
                     (string->number (list-ref details (+ 6 (* i 8) combo-legs-index))) ; short-sale-slot
                     (list-ref details (+ 7 (* i 8) combo-legs-index)) ; designated-location
                     (string->number (list-ref details (+ 8 (* i 8) combo-legs-index))) ; exempt-code
                     ))
             (range combo-legs-size)) ; combo-legs
        (map (λ (i) (string->number (list-ref details (+ 1 (* i 1) order-combo-legs-index))))
             (range order-combo-legs-size)) ; order-combo-legs
        (apply hash (take (drop details (+ 1 smart-combo-routing-params-index))
                          (* 2 smart-combo-routing-params-size)))
        (string->number (list-ref details scale-init-level-size-index)) ; scale-init-level-size
        (string->number (list-ref details (+ 1 scale-init-level-size-index))) ; scale-subs-level-size
        (string->number (list-ref details (+ 2 scale-init-level-size-index))) ; scale-price-increment
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 3 scale-init-level-size-index)))) ; scale-price-adjust-value
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 4 scale-init-level-size-index)))) ; scale-price-adjust-interval
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 5 scale-init-level-size-index)))) ; scale-profit-offset
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (if (equal? "1" (list-ref details (+ 6 scale-init-level-size-index))) #t #f)) ; scale-auto-reset
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 7 scale-init-level-size-index)))) ; scale-init-position
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 8 scale-init-level-size-index)))) ; scale-init-fill-quantity
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (if (equal? "1" (list-ref details (+ 9 scale-init-level-size-index))) #t #f)) ; scale-random-percent
        (list-ref details hedge-type-index) ; hedge-type
        (if (equal? "" (list-ref details hedge-type-index))
            "" (list-ref details (+ 1 hedge-type-index))) ; hedge-param
        (if (equal? "1" (list-ref details opt-out-smart-routing-index)) #t #f) ; opt-out-smart-routing
        (list-ref details (+ 1 opt-out-smart-routing-index)) ; clearing-account
        (string->symbol (string-downcase (list-ref details (+ 2 opt-out-smart-routing-index)))) ; clearing-intent
        (if (equal? "1" (list-ref details (+ 3 opt-out-smart-routing-index))) #t #f) ; not-held
        (if (equal? 0 delta-neutral-contract-indicator)
            #f (string->number (list-ref details (+ 5 opt-out-smart-routing-index)))) ; delta-neutral-underlying-contract-id
        (if (equal? 0 delta-neutral-contract-indicator)
            #f (string->number (list-ref details (+ 6 opt-out-smart-routing-index)))) ; delta-neutral-underlying-delta
        (if (equal? 0 delta-neutral-contract-indicator)
            #f (string->number (list-ref details (+ 7 opt-out-smart-routing-index)))) ; delta-neutral-underlying-price
        (list-ref details algo-strategy-index) ; algo-strategy
        (list) ; algo-strategy-params
        (if (equal? "1" (list-ref details solicited-index)) #t #f) ; solicited
        (if (equal? "1" (list-ref details (+ 1 solicited-index))) #t #f) ; what-if
        (list-ref details (+ 2 solicited-index)) ; status
        ; there are some bits in the Java code that attempt to use Double.MAX as a null value.
        ; usually, these are later removed, but in a few cases like the ones below, they are
        ; not removed and need to be explicitly handled as they are sent over the wire.
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 3 solicited-index)))
            #f (string->number (list-ref details (+ 3 solicited-index)))) ; initial-margin
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 4 solicited-index)))
            #f (string->number (list-ref details (+ 4 solicited-index)))) ; maintenance-margin
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 5 solicited-index)))
            #f (string->number (list-ref details (+ 5 solicited-index)))) ; equity-with-loan
        (string->number (list-ref details (+ 6 solicited-index))) ; commission
        (string->number (list-ref details (+ 7 solicited-index))) ; minimum-commission
        (string->number (list-ref details (+ 8 solicited-index))) ; maximum-commission
        (list-ref details (+ 9 solicited-index)) ; commission-currency
        (list-ref details (+ 10 solicited-index)) ; warning-text
        (if (equal? "1" (list-ref details (+ 11 solicited-index))) #t #f) ; randomize-size
        (if (equal? "1" (list-ref details (+ 12 solicited-index))) #t #f) ; randomize-price
        (if (equal? "PEG BENCH" (list-ref details 14))
            (string->number (list-ref details (+ 13 solicited-index))) #f) ; reference-contract-id
        (if (equal? "PEG BENCH" (list-ref details 14))
            (if (equal? "1" (list-ref details (+ 14 solicited-index))) #t #f) #f) ; is-pegged-change-amount-decrease
        (if (equal? "PEG BENCH" (list-ref details 14))
            (string->number (list-ref details (+ 15 solicited-index))) #f) ; pegged-change-amount
        (if (equal? "PEG BENCH" (list-ref details 14))
            (string->number (list-ref details (+ 16 solicited-index))) #f) ; reference-change-amount
        (if (equal? "PEG BENCH" (list-ref details 14))
            (list-ref details (+ 17 solicited-index)) "") ; reference-exchange-id
        (list) ; conditions
        (if (equal? "None" (list-ref details adjusted-order-type-index))
            #f (string->symbol (string-downcase (string-replace (list-ref details adjusted-order-type-index) "_" "-")))) ; adjusted-order-type
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 1 adjusted-order-type-index)))
            #f (string->number (list-ref details (+ 1 adjusted-order-type-index)))) ; trigger-price
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 2 adjusted-order-type-index)))
            #f (string->number (list-ref details (+ 2 adjusted-order-type-index)))) ; trail-stop-price
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 3 adjusted-order-type-index)))
            #f (string->number (list-ref details (+ 3 adjusted-order-type-index)))) ; limit-price-offset
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 4 adjusted-order-type-index)))
            #f (string->number (list-ref details (+ 4 adjusted-order-type-index)))) ; adjusted-stop-price
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 5 adjusted-order-type-index)))
            #f (string->number (list-ref details (+ 5 adjusted-order-type-index)))) ; adjusted-stop-limit-price
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 6 adjusted-order-type-index)))
            #f (string->number (list-ref details (+ 6 adjusted-order-type-index)))) ; adjusted-trailing-amount
        (string->number (list-ref details (+ 7 adjusted-order-type-index))) ; adjustable-trailing-unit
        (list-ref details (+ 8 adjusted-order-type-index)) ; soft-dollar-tier-name
        (list-ref details (+ 9 adjusted-order-type-index)) ; soft-dollar-tier-val
        (list-ref details (+ 10 adjusted-order-type-index)) ; soft-dollar-tier-display-name
        ))]
    ; next valid id
    [(list "9" version order-id) (next-valid-id-rsp (string->number order-id))]
    ; contract details
    [(list-rest "10" version details) (contract-details-rsp
                                       (string->number (list-ref details 0)) ; request-id
                                       (list-ref details 1) ; symbol
                                       (string->symbol (string-downcase (list-ref details 2))) ; security-type
                                       (if (equal? "" (list-ref details 3))
                                           #f (string->date (list-ref details 3) "~Y~m~d")) ; expiry
                                       (string->number (list-ref details 4)) ; strike
                                       (match (list-ref details 5)
                                         ["C" 'call]
                                         ["P" 'put]
                                         [_ #f]) ; right
                                       (list-ref details 6) ; exchange
                                       (list-ref details 7) ; currency
                                       (list-ref details 8) ; local-symbol
                                       (list-ref details 9) ; market-name
                                       (list-ref details 10) ; trading-class
                                       (string->number (list-ref details 11)) ; contract-id
                                       (string->number (list-ref details 12)) ; minimum-tick-increment
                                       (list-ref details 13) ; multiplier
                                       (string-split (list-ref details 14) ",") ; order-types
                                       (string-split (list-ref details 15) ",") ; valid-exchanges
                                       (string->number (list-ref details 16)) ; price-magnifier
                                       (string->number (list-ref details 17)) ; underlying-contract-id
                                       (list-ref details 18) ; long-name
                                       (list-ref details 19) ; primary-exchange
                                       (list-ref details 20) ; contract-month
                                       (list-ref details 21) ; industry
                                       (list-ref details 22) ; category
                                       (list-ref details 23) ; subcategory
                                       (list-ref details 24) ; time-zone-id
                                       (string-split (list-ref details 25) ";") ; trading-hours
                                       (string-split (list-ref details 26) ";") ; liquid-hours
                                       (list-ref details 27) ; ev-rule
                                       (list-ref details 28) ; ev-multiplier
                                       )]
    ; execution
    [(list-rest "11" version details) (execution-rsp
                                       (string->number (list-ref details 0)) ; request-id
                                       (string->number (list-ref details 1)) ; order-id
                                       (string->number (list-ref details 2)) ; contract-id
                                       (list-ref details 3) ; symbol
                                       (string->symbol (string-downcase (list-ref details 4))) ; security-type
                                       (if (equal? "" (list-ref details 5))
                                           #f (string->date (list-ref details 5) "~Y~m~d")) ; expiry
                                       (string->number (list-ref details 6)) ; strike
                                       (match (list-ref details 7)
                                         ["C" 'call]
                                         ["P" 'put]
                                         [_ #f]) ; right
                                       (string->number (list-ref details 8)) ; multiplier
                                       (list-ref details 9) ; exchange
                                       (list-ref details 10) ; currency
                                       (list-ref details 11) ; local-symbol
                                       (list-ref details 12) ; trading-class
                                       (list-ref details 13) ; execution-id
                                       ; take out the time-zone-name as srfi/19 does not handle this. assume local time zone
                                       (string->date (first (regexp-match #px"([0-9]{8} +[0-9]{2}:[0-9]{2}:[0-9]{2})( [A-Z]+)?"
                                                                          (list-ref details 14))) "~Y~m~d ~H:~M:~S") ; timestamp
                                       (list-ref details 15) ; account
                                       (list-ref details 16) ; executing-exchange
                                       (list-ref details 17) ; side
                                       (string->number (list-ref details 18)) ; shares
                                       (string->number (list-ref details 19)) ; price
                                       (string->number (list-ref details 20)) ; perm-id
                                       (string->number (list-ref details 21)) ; client-id
                                       (string->number (list-ref details 22)) ; liquidation
                                       (string->number (list-ref details 23)) ; cumulative-quantity
                                       (string->number (list-ref details 24)) ; average-price
                                       (list-ref details 25) ; order-reference
                                       (list-ref details 26) ; ev-rule
                                       (string->number (list-ref details 27)) ; ev-multiplier
                                       (list-ref details 28) ; model-code
                                       )]
    ; managed accounts
    [(list-rest "15" num-accts accts) accts]
    ; current timestamp
    [(list "106" date-str) (string->date (substring date-str 0 (- (string-length date-str) 4)) ; chop off timezone
                                         "~Y~m~d ~H:~M:~S")]
    [_ (string-split (bytes->string/utf-8 str) "\0")]))
