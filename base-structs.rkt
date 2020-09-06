#lang racket/base

(require gregor
         racket/contract
         racket/list)

(provide
 (contract-out
  [struct bar
    ((moment moment?)
     (open rational?)
     (high rational?)
     (low rational?)
     (close rational?)
     (volume integer?)
     (weighted-average-price rational?)
     (count integer?))]
  [struct combo-leg
    ((contract-id integer?)
     (ratio integer?)
     (action (or/c 'buy 'sell 'sshort))
     (exchange string?)
     (open-close (or/c 'same 'open 'close #f))
     (short-sale-slot (or/c 0 1 2))
     (designated-location string?)
     (exempt-code integer?))]
  [struct condition
    ((type (or/c 'price 'time 'margin 'execution 'volume 'percent-change))
     (boolean-operator (or/c 'and 'or))
     (comparator (or/c 'less-than 'greater-than #f))
     (value (or/c rational? moment? #f))
     (contract-id (or/c integer? #f))
     (exchange (or/c string? #f))
     (trigger-method (or/c 'default 'double-bid/ask 'last 'double-last 'bid/ask 'last-of-bid/ask 'mid-point #f))
     (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                          'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f))
     (symbol (or/c string? #f)))]
  [tick-type-hash (hash/c integer? symbol?)]))

(struct bar
  (moment
   open
   high
   low
   close
   volume
   weighted-average-price
   count)
  #:transparent)

(struct combo-leg
  (contract-id
   ratio
   action
   exchange
   open-close
   short-sale-slot
   designated-location
   exempt-code)
  #:transparent)

(struct condition
  (type
   boolean-operator
   comparator
   value
   contract-id
   exchange
   trigger-method
   security-type
   symbol)
  #:transparent)

; defined as a list of lists in case we need a map of symbol -> int in the future
(define tick-types
  '((0 bid-size)
    (1 bid-price)
    (2 ask-price)
    (3 ask-size)
    (4 last-price)
    (5 last-size)
    (6 high)
    (7 low)
    (8 volume)
    (9 close)
    (10 bid-option-computation)
    (11 ask-option-computation)
    (12 last-option-computation)
    (13 model-option-computation)
    (14 open)
    (15 13-week-low)
    (16 13-week-high)
    (17 26-week-low)
    (18 26-week-high)
    (19 52-week-low)
    (20 52-week-high)
    (21 average-volume)
    (22 open-interest)
    (23 option-historical-volatility)
    (24 option-implied-volatility)
    (25 option-bid-exchange)
    (26 option-ask-exchange)
    (27 option-call-open-interest)
    (28 option-put-open-interest)
    (29 option-call-volume)
    (30 option-put-volume)
    (31 index-future-premium)
    (32 bid-exchange)
    (33 ask-exchange)
    (34 auction-volume)
    (35 auction-price)
    (36 auction-imbalance)
    (37 mark-price)
    (38 bid-efp-computation)
    (39 ask-efp-computation)
    (40 last-efp-computation)
    (41 open-efp-computation)
    (42 high-efp-computation)
    (43 low-efp-computation)
    (44 close-efp-computation)
    (45 last-timestamp)
    (46 shortable)
    (47 fundamental-ratios)
    (48 rt-volume)
    (49 halted)
    (50 bid-yield)
    (51 ask-yield)
    (52 last-yield)
    (53 custom-option-computation)
    (54 trade-count)
    (55 trade-rate)
    (56 volume-rate)
    (57 last-rth-trade)
    (58 real-time-historical-volatility)
    (59 ib-dividends)
    (60 bond-factor-multiplier)
    (61 regulatory-imbalance)
    (62 news-tick)
    (63 3-minute-volume)
    (64 5-minute-volume)
    (65 10-minute-volume)
    (66 delayed-bid)
    (67 delayed-ask)
    (68 delayed-last)
    (69 delayed-bid-size)
    (70 delayed-ask-size)
    (71 delayed-last-size)
    (72 delayed-high)
    (73 delayed-low)
    (74 delayed-volume)
    (75 delayed-close)
    (76 delayed-open)
    (77 reportable-trade-volume)
    (78 creditman-mark-price)
    (79 creditman-slow-mark-price)
    (80 delayed-bid-option-computation)
    (81 delayed-ask-option-computation)
    (82 delayed-last-option-computation)
    (83 delayed-model-option-computation)
    (84 last-exchange)
    (85 last-regulatory-time)
    (86 future-open-interest)
    (87 average-option-volume)
    (88 delayed-last-timestamp)
    (89 shortable-shares)))

(define tick-type-hash (apply hash (flatten tick-types)))
