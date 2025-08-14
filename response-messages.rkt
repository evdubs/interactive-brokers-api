#lang racket/base

(require gregor
         racket/contract
         racket/list
         racket/match
         racket/string
         "base-structs.rkt")

(provide
 (contract-out
  [struct account-value-rsp
    ((key string?)
     (value string?)
     (currency string?)
     (account-name string?))]
  [struct commission-report-rsp
    ((execution-id string?)
     (commission rational?)
     (currency string?)
     (realized-pnl (or/c rational? #f))
     (yield (or/c rational? #f))
     (yield-redemption-date (or/c integer? #f)))]
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
     (ev-multiplier string?)
     (security-ids hash?)
     (agg-group integer?)
     (underlying-symbol string?)
     (underlying-security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                     'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f))
     (market-rule-ids (listof string?))
     (real-expiry (or/c date? #f))
     (stock-type string?)
     (minimum-size rational?)
     (size-increment rational?)
     (suggested-size-increment rational?)
     (fund-name string?)
     (fund-family string?)
     (fund-type string?)
     (fund-front-load string?)
     (fund-back-load string?)
     (fund-back-load-time-interval string?)
     (fund-management-fee string?)
     (fund-closed boolean?)
     (fund-closed-for-new-investors boolean?)
     (fund-closed-for-new-money boolean?)
     (fund-notify-amount (or/c rational? #f))
     (fund-minimum-initial-purchase (or/c rational? #f))
     (fund-subsequent-minimum-purchase (or/c rational? #f))
     (fund-blue-sky-states string?)
     (fund-blue-sky-territories string?)
     (fund-distribution-policy (or/c 'accumulation 'income #f))
     (fund-asset-type (or/c 'money-market 'fixed-income 'multi-asset 'equity
                            'sector 'guaranteed 'alternative 'others #f))
     (ineligibility-reasons hash?))]
  [struct err-rsp
    ((id integer?)
     (error-code integer?)
     (error-msg string?)
     (advanced-order-reject string?))]
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
     (timestamp moment?)
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
     (ev-multiplier (or/c rational? #f))
     (model-code string?)
     (last-liquidity integer?)
     (pending-price-revision boolean?))]
  [struct historical-data-rsp
    ((request-id integer?)
     (start-moment moment?)
     (end-moment moment?)
     (bars (listof bar?)))]
  [struct market-data-rsp
    ((request-id integer?)
     (type symbol?)
     (value rational?))]
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
     (good-after-time (or/c moment? #f))
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
     (combo-legs-description string?)
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
     (algo-strategy-params hash?)
     (solicited boolean?)
     (what-if boolean?)
     (status string?)
     (initial-margin-before (or/c rational? #f))
     (maintenance-margin-before (or/c rational? #f))
     (equity-with-loan-before (or/c rational? #f))
     (initial-margin-change (or/c rational? #f))
     (maintenance-margin-change (or/c rational? #f))
     (equity-with-loan-change (or/c rational? #f))
     (initial-margin-after (or/c rational? #f))
     (maintenance-margin-after (or/c rational? #f))
     (equity-with-loan-after (or/c rational? #f))
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
     (conditions (listof condition?))
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
     (soft-dollar-tier-display-name string?)
     (cash-quantity rational?)
     (dont-use-auto-price-for-hedge boolean?)
     (is-oms-container boolean?)
     (discretionary-up-to-limit-price boolean?)
     (use-price-management-algo boolean?)
     (duration integer?)
     (post-to-ats (or/c integer? #f))
     (minimum-trade-quantity (or/c integer? #f))
     (minimum-compete-size (or/c integer? #f))
     (compete-against-best-offset (or/c rational? #f))
     (mid-offset-at-whole (or/c rational? #f))
     (mid-offset-at-half (or/c rational? #f))
     (customer-account string?)
     (professional-customer boolean?)
     (bond-accrued-interest (or/c rational? #f)))]
  [struct option-market-data-rsp
    ((request-id integer?)
     (tick-type symbol?)
     (tick-attrib (or/c 'return 'price))
     (implied-volatility rational?)
     (delta rational?)
     (price rational?)
     (pv-dividend rational?)
     (gamma rational?)
     (vega rational?)
     (theta rational?)
     (underlying-price rational?))]
  [struct order-status-rsp
    ((order-id integer?)
     (status (or/c 'pending-submit 'pending-cancel 'pre-submitted 'submitted
                   'api-cancelled 'cancelled 'filled 'inactive))
     (filled rational?)
     (remaining rational?)
     (average-fill-price rational?)
     (perm-id integer?)
     (parent-id integer?)
     (last-fill-price rational?)
     (client-id integer?)
     (why-held string?)
     (market-cap-price rational?))]
  [struct portfolio-value-rsp
    ((contract-id integer?)
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
     (position rational?)
     (market-price rational?)
     (market-value rational?)
     (average-cost rational?)
     (unrealized-pnl rational?)
     (realized-pnl rational?)
     (account-name string?))])
 parse-msg)

(struct account-value-rsp
  (key
   value
   currency
   account-name)
  #:transparent)

(struct commission-report-rsp
  (execution-id
   commission
   currency
   realized-pnl
   yield
   yield-redemption-date)
  #:transparent)

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
   security-ids
   agg-group
   underlying-symbol
   underlying-security-type
   market-rule-ids
   real-expiry
   stock-type
   minimum-size
   size-increment
   suggested-size-increment
   fund-name
   fund-family
   fund-type
   fund-front-load
   fund-back-load
   fund-back-load-time-interval
   fund-management-fee
   fund-closed
   fund-closed-for-new-investors
   fund-closed-for-new-money
   fund-notify-amount
   fund-minimum-initial-purchase
   fund-subsequent-minimum-purchase
   fund-blue-sky-states
   fund-blue-sky-territories
   fund-distribution-policy
   fund-asset-type
   ineligibility-reasons)
  #:transparent)

(struct err-rsp
  (id
   error-code
   error-msg
   advanced-order-reject)
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
   model-code
   last-liquidity
   pending-price-revision)
  #:transparent)

(struct historical-data-rsp
  (request-id
   start-moment
   end-moment
   bars)
  #:transparent)

(struct market-data-rsp
  (request-id
   type
   value)
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
   combo-legs-description
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
   initial-margin-before
   maintenance-margin-before
   equity-with-loan-before
   initial-margin-change
   maintenance-margin-change
   equity-with-loan-change
   initial-margin-after
   maintenance-margin-after
   equity-with-loan-after
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
   soft-dollar-tier-display-name
   cash-quantity
   dont-use-auto-price-for-hedge
   is-oms-container
   discretionary-up-to-limit-price
   use-price-management-algo
   duration
   post-to-ats
   minimum-trade-quantity
   minimum-compete-size
   compete-against-best-offset
   mid-offset-at-whole
   mid-offset-at-half
   customer-account
   professional-customer
   bond-accrued-interest)
  #:transparent)

(struct option-market-data-rsp
  (request-id
   tick-type
   tick-attrib
   implied-volatility
   delta
   price
   pv-dividend
   gamma
   vega
   theta
   underlying-price)
  #:transparent)

(struct order-status-rsp
  (order-id
   status
   filled
   remaining
   average-fill-price
   perm-id
   parent-id
   last-fill-price
   client-id
   why-held
   market-cap-price)
  #:transparent)

(struct portfolio-value-rsp
  (contract-id
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
   position
   market-price
   market-value
   average-cost
   unrealized-pnl
   realized-pnl
   account-name)
  #:transparent)

; ensure string->number conversions try to exactly represent the provided decimal
(read-decimal-as-inexact #f)

; convert a byte string message received over the wire to the appropriate structure
(define/contract (parse-msg str)
  (-> bytes? (or/c account-value-rsp?
                   commission-report-rsp?
                   contract-details-rsp?
                   err-rsp?
                   execution-rsp?
                   historical-data-rsp?
                   (listof string?)
                   market-data-rsp?
                   moment?
                   next-valid-id-rsp?
                   open-order-rsp?
                   option-market-data-rsp?
                   order-status-rsp?
                   portfolio-value-rsp?))
  (match (string-split (bytes->string/utf-8 str) "\0")
    ; tick price
    [(list-rest "1" "6" request-id type value details)
     (market-data-rsp
      (string->number request-id)
      (hash-ref tick-type-hash (string->number type))
      (string->number value))]
    ; tick size
    [(list "2" "6" request-id type value)
     (market-data-rsp
      (string->number request-id)
      (hash-ref tick-type-hash (string->number type))
      (string->number value))]
    ; order status
    [(list "3" order-id status filled remaining average-fill-price perm-id parent-id
           last-fill-price client-id why-held market-cap-price)
     (order-status-rsp
      (string->number order-id)
      (match status
        ["PendingSubmit" 'pending-submit]
        ["PendingCancel" 'pending-cancel]
        ["PreSubmitted" 'pre-submitted]
        ["Submitted" 'submitted]
        ["ApiCancelled" 'api-cancelled]
        ["Cancelled" 'cancelled]
        ["Filled" 'filled]
        ["Inactive" 'inactive])
      (string->number filled)
      (string->number remaining)
      (string->number average-fill-price)
      (string->number perm-id)
      (string->number parent-id)
      (string->number last-fill-price)
      (string->number client-id)
      why-held
      (string->number market-cap-price))]
    ; generic error message
    ; ignoring error responses with version < 2
    [(list "4" "2" id error-code message advanced-order-reject)
     (err-rsp (string->number id) (string->number error-code) message advanced-order-reject)]
    ; open order
    [(list-rest "5" details)
     (let* ([combo-legs-index 77]
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
            [algo-strategy-params-size (if (equal? "" (list-ref details algo-strategy-index))
                                  0
                                  (string->number (list-ref details (+ 1 algo-strategy-index))))]
            [solicited-index (+ 1 algo-strategy-index (if (< 0 algo-strategy-params-size) 1 0) (* 2 algo-strategy-params-size))]
            [conditions-index (if (equal? "PEG BENCH" (list-ref details 14))
                                  (+ 24 solicited-index)
                                  (+ 19 solicited-index))]
            [conditions-size (string->number (list-ref details conditions-index))]
            [conditions-offsets (foldl (λ (i res)
                                         (append res (list (match (list-ref details (last res))
                                                             ["1" (+ 7 (last res))]
                                                             ["3" (+ 4 (last res))]
                                                             ["4" (+ 4 (last res))]
                                                             ["5" (+ 5 (last res))]
                                                             ["6" (+ 6 (last res))]
                                                             ["7" (+ 6 (last res))]))))
                                       (list (+ 1 conditions-index))
                                       (range conditions-size))]
            [adjusted-order-type-index (+ (last conditions-offsets) (if (< 0 conditions-size) 2 0))])
       (open-order-rsp
        (string->number (list-ref details 0)) ; order-id
        (string->number (list-ref details 1)) ; contract-id
        (list-ref details 2) ; symbol
        (string->symbol (string-downcase (list-ref details 3))) ; security-type
        (if (equal? "" (list-ref details 4))
            #f (parse-date (list-ref details 4) "yyyyMMdd")) ; expiry
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
        (equal? "1" (list-ref details 25)) ; outside-rth
        (equal? "1" (list-ref details 26)) ; hidden
        (string->number (list-ref details 27)) ; discretionary-amount
        ; IBKR supplies tzids like US/Eastern which are deprecated.
        ; An additional package like `tzdata-legacy` may need to be installed.
        (if (equal? "" (list-ref details 28))
            #f (parse-moment (list-ref details 28) "yyyyMMdd HH:mm:ss VV")) ; good-after-time
        ; deprecated shares allocation
        (list-ref details 30) ; advisor-group
        (list-ref details 31) ; advisor-method
        (list-ref details 32) ; advisor-percentage
        "" ; (list-ref details 33) deprecated advisor-profile
        (list-ref details 33) ; model-code
        (if (equal? "" (list-ref details 34))
            #f (parse-date (list-ref details 34) "yyyyMMdd")) ; good-till-date
        (list-ref details 35) ; rule-80-a
        (string->number (list-ref details 36)) ; percent-offset
        (list-ref details 37) ; settling-firm
        (string->number (list-ref details 38)) ; short-sale-slot
        (list-ref details 39) ; designated-location
        (string->number (list-ref details 40)) ; exempt-code
        (match (list-ref details 41)
          ["1" 'match]
          ["2" 'improvement]
          ["3" 'transparent]
          [_ #f]) ; auction-strategy
        (string->number (list-ref details 42)) ; starting-price
        (string->number (list-ref details 43)) ; stock-ref-price
        (string->number (list-ref details 44)) ; delta
        (string->number (list-ref details 45)) ; stock-range-lower
        (string->number (list-ref details 46)) ; stock-range-upper
        (string->number (list-ref details 47)) ; display-size
        (equal? "1" (list-ref details 48)) ; block-order
        (equal? "1" (list-ref details 49)) ; sweep-to-fill
        (equal? "1" (list-ref details 50)) ; all-or-none
        (string->number (list-ref details 51)) ; minimum-quantity
        (string->number (list-ref details 52)) ; oca-type
        (equal? "1" (list-ref details 53)) ; electronic-trade-only
        (equal? "1" (list-ref details 54)) ; firm-quote-only
        (string->number (list-ref details 55)) ; nbbo-price-cap
        (string->number (list-ref details 56)) ; parent-id
        (string->number (list-ref details 57)) ; trigger-method
        (string->number (list-ref details 58)) ; volatility
        (string->number (list-ref details 59)) ; volatility-type
        (list-ref details 60) ; delta-neutral-order-type
        (string->number (list-ref details 61)) ; delta-neutral-aux-price
        (string->number (list-ref details 62)) ; delta-neutral-contract-id
        (list-ref details 63) ; delta-neutral-settling-firm
        (list-ref details 64) ; delta-neutral-clearing-account
        (list-ref details 65) ; delta-neutral-clearing-intent
        (match (list-ref details 66)
          ["O" 'open]
          ["C" 'close]
          [_ #f]) ; delta-neutral-open-close
        (equal? "1" (list-ref details 67)) ; delta-neutral-short-sale
        (string->number (list-ref details 68)) ; delta-neutral-short-sale-slot
        (list-ref details 69) ; delta-neutral-designated-location
        (string->number (list-ref details 70)) ; continuous-update
        (string->number (list-ref details 71)) ; reference-price-type
        (string->number (list-ref details 72)) ; trailing-stop-price
        (string->number (list-ref details 73)) ; trailing-percent
        (string->number (list-ref details 74)) ; basis-points
        (string->number (list-ref details 75)) ; basis-points-type
        (list-ref details 76) ; combo-legs-description
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
                          (* 2 smart-combo-routing-params-size))) ; smart-combo-routing-params
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
            #f (equal? "1" (list-ref details (+ 6 scale-init-level-size-index)))) ; scale-auto-reset
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 7 scale-init-level-size-index)))) ; scale-init-position
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (string->number (list-ref details (+ 8 scale-init-level-size-index)))) ; scale-init-fill-quantity
        (if (equal? "" (list-ref details (+ 2 scale-init-level-size-index)))
            #f (equal? "1" (list-ref details (+ 9 scale-init-level-size-index)))) ; scale-random-percent
        (list-ref details hedge-type-index) ; hedge-type
        (if (equal? "" (list-ref details hedge-type-index))
            "" (list-ref details (+ 1 hedge-type-index))) ; hedge-param
        (equal? "1" (list-ref details opt-out-smart-routing-index)) ; opt-out-smart-routing
        (list-ref details (+ 1 opt-out-smart-routing-index)) ; clearing-account
        (string->symbol (string-downcase (list-ref details (+ 2 opt-out-smart-routing-index)))) ; clearing-intent
        (equal? "1" (list-ref details (+ 3 opt-out-smart-routing-index))) ; not-held
        (if (equal? 0 delta-neutral-contract-indicator)
            #f (string->number (list-ref details (+ 5 opt-out-smart-routing-index)))) ; delta-neutral-underlying-contract-id
        (if (equal? 0 delta-neutral-contract-indicator)
            #f (string->number (list-ref details (+ 6 opt-out-smart-routing-index)))) ; delta-neutral-underlying-delta
        (if (equal? 0 delta-neutral-contract-indicator)
            #f (string->number (list-ref details (+ 7 opt-out-smart-routing-index)))) ; delta-neutral-underlying-price
        (list-ref details algo-strategy-index) ; algo-strategy
        (apply hash (take (drop details (+ 2 algo-strategy-index))
                          (* 2 algo-strategy-params-size))) ; algo-strategy-params
        (equal? "1" (list-ref details solicited-index)) ; solicited
        (equal? "1" (list-ref details (+ 1 solicited-index))) ; what-if
        (list-ref details (+ 2 solicited-index)) ; status
        ; there are some bits in the Java code that attempt to use Double.MAX as a null value.
        ; usually, these are later removed, but in a few cases like the ones below, they are
        ; not removed and need to be explicitly handled as they are sent over the wire.
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 3 solicited-index)))
            #f (string->number (list-ref details (+ 3 solicited-index)))) ; initial-margin-before
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 4 solicited-index)))
            #f (string->number (list-ref details (+ 4 solicited-index)))) ; maintenance-margin-before
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 5 solicited-index)))
            #f (string->number (list-ref details (+ 5 solicited-index)))) ; equity-with-loan-before
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 6 solicited-index)))
            #f (string->number (list-ref details (+ 6 solicited-index)))) ; initial-margin-change
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 7 solicited-index)))
            #f (string->number (list-ref details (+ 7 solicited-index)))) ; maintenance-margin-change
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 8 solicited-index)))
            #f (string->number (list-ref details (+ 8 solicited-index)))) ; equity-with-loan-change
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 9 solicited-index)))
            #f (string->number (list-ref details (+ 9 solicited-index)))) ; initial-margin-after
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 10 solicited-index)))
            #f (string->number (list-ref details (+ 10 solicited-index)))) ; maintenance-margin-after
        (if (equal? "1.7976931348623157E308" (list-ref details (+ 11 solicited-index)))
            #f (string->number (list-ref details (+ 11 solicited-index)))) ; equity-with-loan-after
        (string->number (list-ref details (+ 12 solicited-index))) ; commission
        (string->number (list-ref details (+ 13 solicited-index))) ; minimum-commission
        (string->number (list-ref details (+ 14 solicited-index))) ; maximum-commission
        (list-ref details (+ 15 solicited-index)) ; commission-currency
        (list-ref details (+ 16 solicited-index)) ; warning-text
        (equal? "1" (list-ref details (+ 17 solicited-index))) ; randomize-size
        (equal? "1" (list-ref details (+ 18 solicited-index))) ; randomize-price
        (if (equal? "PEG BENCH" (list-ref details 14))
            (string->number (list-ref details (+ 19 solicited-index))) #f) ; reference-contract-id
        (if (equal? "PEG BENCH" (list-ref details 14))
            (equal? "1" (list-ref details (+ 20 solicited-index))) #f) ; is-pegged-change-amount-decrease
        (if (equal? "PEG BENCH" (list-ref details 14))
            (string->number (list-ref details (+ 21 solicited-index))) #f) ; pegged-change-amount
        (if (equal? "PEG BENCH" (list-ref details 14))
            (string->number (list-ref details (+ 22 solicited-index))) #f) ; reference-change-amount
        (if (equal? "PEG BENCH" (list-ref details 14))
            (list-ref details (+ 23 solicited-index)) "") ; reference-exchange-id
        (map (λ (i)
               (match (list-ref details i)
                 ["1" (condition
                       'price ; type
                       ; we have a default case below because we have received "n" before, which shouldn't be possible,
                       ; but the Java library treats everything not "a" as the 'or case
                       (match (list-ref details (+ 1 i)) ["a" 'and] ["o" 'or] [_ 'or]) ; boolean-operator
                       (match (list-ref details (+ 2 i)) ["0" 'less-than] ["1" 'greater-than]) ; comparator
                       (string->number (list-ref details (+ 3 i))) ; price
                       (string->number (list-ref details (+ 4 i))) ; contract-id
                       (list-ref details (+ 5 i)) ; exchange
                       (match (list-ref details (+ 6 i))
                         ["0" 'default]
                         ["1" 'double-bid/ask]
                         ["2" 'last]
                         ["3" 'double-last]
                         ["4" 'bid/ask]
                         ["7" 'last-of-bid/ask]
                         ["8" 'mid-point]) ; trigger-method
                       #f ; security-type
                       #f)] ; symbol
                 ["3" (condition
                       'time ; type
                       (match (list-ref details (+ 1 i)) ["a" 'and] ["o" 'or]) ; boolean-operator
                       (match (list-ref details (+ 2 i)) ["0" 'less-than] ["1" 'greater-than]) ; comparator
                       (parse-moment (list-ref details (+ 3 i)) "yyyyMMdd HH:mm:ss VV") ; time
                       #f ; contract-id
                       #f ; exchange
                       #f ; trigger-method
                       #f ; security-type
                       #f)] ; symbol
                 ["4" (condition
                       'margin ; type
                       (match (list-ref details (+ 1 i)) ["a" 'and] ["o" 'or]) ; boolean-operator
                       (match (list-ref details (+ 2 i)) ["0" 'less-than] ["1" 'greater-than]) ; comparator
                       (string->number (list-ref details (+ 3 i))) ; margin-percent
                       #f ; contract-id
                       #f ; exchange
                       #f ; trigger-method
                       #f ; security-type
                       #f)] ; symbol
                 ["5" (condition
                       'execution
                       (match (list-ref details (+ 1 i)) ["a" 'and] ["o" 'or]) ; boolean-operator
                       #f ; comparator
                       #f ; value
                       #f ; contract-id
                       (list-ref details (+ 3 i)) ; exchange
                       #f ; trigger-method
                       (string->symbol (string-downcase (list-ref details (+ 2 i)))) ; security-type
                       (list-ref details (+ 4 i)))] ; symbol
                 ["6" (condition
                       'volume ; type
                       (match (list-ref details (+ 1 i)) ["a" 'and] ["o" 'or]) ; boolean-operator
                       (match (list-ref details (+ 2 i)) ["0" 'less-than] ["1" 'greater-than]) ; comparator
                       (string->number (list-ref details (+ 3 i))) ; volume
                       (string->number (list-ref details (+ 4 i))) ; contract-id
                       (list-ref details (+ 5 i)) ; exchange
                       #f ; trigger-method
                       #f ; security-type
                       #f)] ; symbol
                 ["7"(condition
                       'percent-change ; type
                       (match (list-ref details (+ 1 i)) ["a" 'and] ["o" 'or]) ; boolean-operator
                       (match (list-ref details (+ 2 i)) ["0" 'less-than] ["1" 'greater-than]) ; comparator
                       (string->number (list-ref details (+ 3 i))) ; percent-change
                       (string->number (list-ref details (+ 4 i))) ; contract-id
                       (list-ref details (+ 5 i)) ; exchange
                       #f ; trigger-method
                       #f ; security-type
                       #f)])) ; symbol
             (drop-right conditions-offsets 1)) ; conditions
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
        (string->number (list-ref details (+ 11 adjusted-order-type-index))) ; cash-quantity
        (equal? "1" (list-ref details (+ 12 adjusted-order-type-index))) ; dont-use-auto-price-for-hedge
        (equal? "1" (list-ref details (+ 13 adjusted-order-type-index))) ; is-oms-container
        (equal? "1" (list-ref details (+ 14 adjusted-order-type-index))) ; discretionary-up-to-limit-price
        (equal? "1" (list-ref details (+ 15 adjusted-order-type-index))) ; use-price-management-algo
        (string->number (list-ref details (+ 16 adjusted-order-type-index))) ; duration
        (string->number (list-ref details (+ 17 adjusted-order-type-index))) ; post-to-ats
        ; auto-cancel-parent
        (string->number (list-ref details (+ 19 adjusted-order-type-index))) ; minimum-trade-quantity
        (string->number (list-ref details (+ 20 adjusted-order-type-index))) ; minimum-compete-size
        (string->number (list-ref details (+ 21 adjusted-order-type-index))) ; compete-against-best-offset
        (string->number (list-ref details (+ 22 adjusted-order-type-index))) ; mid-offset-at-whole
        (string->number (list-ref details (+ 23 adjusted-order-type-index))) ; mid-offset-at-half
        (list-ref details (+ 24 adjusted-order-type-index)) ; customer-account
        (equal? "1" (list-ref details (+ 25 adjusted-order-type-index))) ; professional-customer
        (string->number (list-ref details (+ 26 adjusted-order-type-index))) ; bond-accrued-interest
        ))]
    ; account value
    [(list "6" version key value currency account-name) (account-value-rsp key value currency account-name)]
    ; portfolio value
    [(list-rest "7" version details) (portfolio-value-rsp
                                      (string->number (list-ref details 0)) ; contract-id
                                      (list-ref details 1) ; symbol
                                      (string->symbol (string-downcase (list-ref details 2))) ; security-type
                                      (if (equal? "" (list-ref details 3))
                                          #f (parse-date (list-ref details 3) "yyyyMMdd")) ; expiry
                                      (string->number (list-ref details 4)) ; strike
                                      (match (list-ref details 5)
                                        ["C" 'call]
                                        ["P" 'put]
                                        [_ #f]) ; right
                                      (string->number (list-ref details 6)) ; multiplier
                                      (list-ref details 7) ; exchange
                                      (list-ref details 8) ; currency
                                      (list-ref details 9) ; local-symbol
                                      (list-ref details 10) ; trading-class
                                      (string->number (list-ref details 11)) ; position
                                      (string->number (list-ref details 12)) ; market-price
                                      (string->number (list-ref details 13)) ; market-value
                                      (string->number (list-ref details 14)) ; average-cost
                                      (string->number (list-ref details 15)) ; unrealized-pnl
                                      (string->number (list-ref details 16)) ; realized-pnl
                                      (list-ref details 17) ; account-name
                                      )]
    ; next valid id
    [(list "9" version order-id) (next-valid-id-rsp (string->number order-id))]
    ; contract details
    [(list-rest "10" details)
     (let* ([security-ids-index 30]
            [security-ids-size (string->number (list-ref details security-ids-index))]
            [agg-group-index (+ 1 security-ids-index (* 2 security-ids-size))]
            [ineligibility-reasons-index (if (equal? "FUND" (list-ref details 2))
                                             (+ 26 agg-group-index) (+ 9 agg-group-index))]
            [ineligibility-reasons-size (string->number (list-ref details ineligibility-reasons-index))])
       (contract-details-rsp
        (string->number (list-ref details 0)) ; request-id
        (list-ref details 1) ; symbol
        (string->symbol (string-downcase (list-ref details 2))) ; security-type
        ; there is an extra last trade date in the message here
        (if (equal? "" (list-ref details 4))
            #f (parse-date (list-ref details 4) "yyyyMMdd")) ; expiry
        (string->number (list-ref details 5)) ; strike
        (match (list-ref details 6)
          ["C" 'call]
          ["P" 'put]
          [_ #f]) ; right
        (list-ref details 7) ; exchange
        (list-ref details 8) ; currency
        (list-ref details 9) ; local-symbol
        (list-ref details 10) ; market-name
        (list-ref details 11) ; trading-class
        (string->number (list-ref details 12)) ; contract-id
        (string->number (list-ref details 13)) ; minimum-tick-increment
        ; md-size-multiplier no longer present
        (list-ref details 14) ; multiplier
        (string-split (list-ref details 15) ",") ; order-types
        (string-split (list-ref details 16) ",") ; valid-exchanges
        (string->number (list-ref details 17)) ; price-magnifier
        (string->number (list-ref details 18)) ; underlying-contract-id
        (list-ref details 19) ; long-name
        (list-ref details 20) ; primary-exchange
        (list-ref details 21) ; contract-month
        (list-ref details 22) ; industry
        (list-ref details 23) ; category
        (list-ref details 24) ; subcategory
        (list-ref details 25) ; time-zone-id
        (string-split (list-ref details 26) ";") ; trading-hours
        (string-split (list-ref details 27) ";") ; liquid-hours
        (list-ref details 28) ; ev-rule
        (list-ref details 29) ; ev-multiplier
        (apply hash (take (drop details (+ 1 security-ids-index))
                          (* 2 security-ids-size))) ; security-ids
        (string->number (list-ref details agg-group-index)) ; agg-group
        (list-ref details (+ 1 agg-group-index)) ; underlying-symbol
        (string->symbol (string-downcase (list-ref details (+ 2 agg-group-index)))) ; underlying-security-type
        (string-split (list-ref details (+ 3 agg-group-index)) ",") ; market-rule-ids
        (if (equal? "" (list-ref details (+ 4 agg-group-index)))
            #f (parse-date (list-ref details (+ 4 agg-group-index)) "yyyyMMdd")) ; real-expiry
        (list-ref details (+ 5 agg-group-index)) ; stock-type
        ; size-minimum-tick not used
        (string->number (list-ref details (+ 6 agg-group-index))) ; minimum-size
        (string->number (list-ref details (+ 7 agg-group-index))) ; size-increment
        (string->number (list-ref details (+ 8 agg-group-index))) ; suggested-size-increment
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 9 agg-group-index)) "") ; fund-name
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 10 agg-group-index)) "") ; fund-family
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 11 agg-group-index)) "") ; fund-type
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 12 agg-group-index)) "") ; fund-front-load
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 13 agg-group-index)) "") ; fund-back-load
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 14 agg-group-index)) "") ; fund-back-load-time-interval
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 15 agg-group-index)) "") ; fund-management-fee
        (if (equal? "FUND" (list-ref details 2)) (equal? "1" (list-ref details (+ 16 agg-group-index))) #f) ; fund-closed
        (if (equal? "FUND" (list-ref details 2)) (equal? "1" (list-ref details (+ 17 agg-group-index))) #f) ; fund-closed-for-new-investors
        (if (equal? "FUND" (list-ref details 2)) (equal? "1" (list-ref details (+ 18 agg-group-index))) #f) ; fund-closed-for-new-money
        (if (and (equal? "FUND" (list-ref details 2)) (equal? "" (list-ref details (+ 19 agg-group-index))))
            (string->number (list-ref details (+ 19 agg-group-index))) #f) ; fund-notify-amount
        (if (and (equal? "FUND" (list-ref details 2)) (equal? "" (list-ref details (+ 20 agg-group-index))))
            (string->number (list-ref details (+ 20 agg-group-index))) #f) ; fund-minimum-initial-purchase
        (if (and (equal? "FUND" (list-ref details 2)) (equal? "" (list-ref details (+ 21 agg-group-index))))
            (string->number (list-ref details (+ 21 agg-group-index))) #f) ; fund-subsequent-minimum-purchase
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 22 agg-group-index)) "") ; fund-blue-sky-states
        (if (equal? "FUND" (list-ref details 2)) (list-ref details (+ 23 agg-group-index)) "") ; fund-blue-sky-territories
        (if (equal? "FUND" (list-ref details 2))
            (match (list-ref details (+ 24 agg-group-index))
              ["N" 'accumulation]
              ["Y" 'income]
              [_ #f])
            #f) ; fund-distribution-policy
        (if (equal? "FUND" (list-ref details 2))
            (match (list-ref details (+ 25 agg-group-index))
              ["000" 'others]
              ["001" 'money-market]
              ["002" 'fixed-income]
              ["003" 'multi-asset]
              ["004" 'equity]
              ["005" 'sector]
              ["006" 'guaranteed]
              ["007" 'alternative]
              [_ #f])
            #f) ; fund-asset-type
        (apply hash (take (drop details (+ 1 ineligibility-reasons-index))
                          (* 2 ineligibility-reasons-size))) ; ineligibility-reasons
        ))]
    ; execution
    [(list-rest "11" details) (execution-rsp
                               (string->number (list-ref details 0)) ; request-id
                               (string->number (list-ref details 1)) ; order-id
                               (string->number (list-ref details 2)) ; contract-id
                               (list-ref details 3) ; symbol
                               (string->symbol (string-downcase (list-ref details 4))) ; security-type
                               (if (equal? "" (list-ref details 5))
                                   #f (parse-date (list-ref details 5) "yyyyMMdd")) ; expiry
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
                               (parse-moment (list-ref details 14) "yyyyMMdd HH:mm:ss VV") ; timestamp
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
                               (string->number (list-ref details 29)) ; last-liquidity
                               (equal? "1" (list-ref details 30)) ; pending-price-revision
                               )]
    ; managed accounts
    [(list-rest "15" num-accts accts) accts]
    ; historical data
    [(list-rest "17" request-id start-moment end-moment bar-count details)
     (historical-data-rsp
      (string->number request-id)
      (parse-moment start-moment "yyyyMMdd HH:mm:ss VV")
      (parse-moment end-moment "yyyyMMdd HH:mm:ss VV")
      (map (λ (i) (bar
                   (parse-moment (list-ref details (* i 8)) "yyyyMMdd HH:mm:ss VV")
                   (string->number (list-ref details (+ 1 (* i 8))))
                   (string->number (list-ref details (+ 2 (* i 8))))
                   (string->number (list-ref details (+ 3 (* i 8))))
                   (string->number (list-ref details (+ 4 (* i 8))))
                   (string->number (list-ref details (+ 5 (* i 8))))
                   (string->number (list-ref details (+ 6 (* i 8))))
                   (string->number (list-ref details (+ 7 (* i 8))))))
           (range (string->number bar-count))))]
    ; commission report
    [(list-rest "59" version details) (commission-report-rsp
                                       (list-ref details 0) ; execution-id
                                       (string->number (list-ref details 1)) ; commission
                                       (list-ref details 2) ; currency
                                       (if (equal? "1.7976931348623157E308" (list-ref details 3))
                                           #f (string->number (list-ref details 3))) ; realized-pnl
                                       (if (equal? "1.7976931348623157E308" (list-ref details 4))
                                           #f (string->number (list-ref details 4))) ; yield
                                       (if (equal? "" (list-ref details 5))
                                           #f (string->number (list-ref details 5))) ; yield-redemption-date
                                       )]
    ; option market data
    [(list "21" request-id tick-type tick-attrib implied-volatility
           delta price pv-dividend gamma vega theta underlying-price)
     (option-market-data-rsp
      (string->number request-id)
      (hash-ref tick-type-hash (string->number tick-type))
      (if (equal? "1" tick-attrib) 'price 'return)
      (rationalize (string->number implied-volatility) 1/1000000)
      (rationalize (string->number delta) 1/1000000)
      (rationalize (string->number price) 1/1000000)
      (rationalize (string->number pv-dividend) 1/1000000)
      (rationalize (string->number gamma) 1/1000000)
      (rationalize (string->number vega) 1/1000000)
      (rationalize (string->number theta) 1/1000000)
      (rationalize (string->number underlying-price) 1/1000000))]
    ; current timestamp
    [(list "106" date-str) (parse-moment date-str "yyyyMMdd HH:mm:ss VV")]
    [_ (string-split (bytes->string/utf-8 str) "\0")]))
