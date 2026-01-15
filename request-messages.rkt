#lang racket/base

(require gregor
         gregor/period
         racket/class
         racket/contract
         racket/match
         racket/string
         "base-structs.rkt")

(provide account-data-req%
         cancel-historical-data-req%
         cancel-market-data-req%
         contract-details-req%
         executions-req%
         ibkr-msg%
         historical-data-req%
         historical-ticks-req%
         market-data-req%
         market-data-type-req%
         open-orders-req%
         place-order-req%
         req-msg<%>
         start-api-req%)

(define/contract ibkr-msg%
  (class/c (init-field [msg-id integer?]
                       [version integer?]))
  (class object%
    (super-new)
    (init-field msg-id version)))

(define req-msg<%>
  ; method to produce a string where each element, regardless of type, is converted
  ; to a string and is null terminated. these elements converted to null-terminated
  ; strings are then all appended together to form the message string.
  (interface ()
    [->string (->m string?)]))

(define/contract account-data-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [subscribe boolean?]
                       [account-code string?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 6]
               [version 2])
    (inherit-field msg-id version)
    (init-field [subscribe #f]
                [account-code ""])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (if subscribe "1" "0") "\0"
       account-code "\0"))))

(define/contract cancel-historical-data-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 25]
               [version 1])
    (inherit-field msg-id version)
    (init-field [request-id 0])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (number->string request-id) "\0"))))

(define/contract cancel-market-data-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 2]
               [version 1])
    (inherit-field msg-id version)
    (init-field [request-id 0])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (number->string request-id) "\0"))))

(define/contract contract-details-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]
                       [contract-id integer?]
                       [symbol string?]
                       [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                            'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f)]
                       [expiry (or/c date? #f)]
                       [strike rational?]
                       [right (or/c 'call 'put #f)]
                       [multiplier (or/c rational? #f)]
                       [exchange string?]
                       [primary-exchange string?]
                       [currency string?]
                       [local-symbol string?]
                       [trading-class string?]
                       [security-id-type (or/c 'cusip 'sedol 'isin 'ric #f)]
                       [security-id string?]
                       [issuer-id string?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 9]
               [version 8])
    (inherit-field msg-id version)
    (init-field [request-id 0]
                [contract-id 0]
                [symbol ""]
                [security-type #f]
                [expiry #f]
                [strike 0]
                [right #f]
                [multiplier #f]
                [exchange ""]
                [primary-exchange ""]
                [currency ""]
                [local-symbol ""]
                [trading-class ""]
                [include-expired ""]
                [security-id-type #f]
                [security-id ""]
                [issuer-id ""])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (number->string request-id) "\0"
       (number->string contract-id) "\0"
       symbol "\0"
       (if (symbol? security-type) (string-upcase (symbol->string security-type)) "") "\0"
       (if (date? expiry) (~t expiry "yyyyMMdd") "") "\0"
       (real->decimal-string strike 3) "\0"
       (if (symbol? right) (string-upcase (substring (symbol->string right) 0 1)) "") "\0"
       (if (rational? multiplier) (number->string multiplier) "") "\0"
       exchange "\0"
       primary-exchange "\0"
       currency "\0"
       local-symbol "\0"
       trading-class "\0"
       include-expired "\0"
       (if (symbol? security-id-type) (string-upcase (symbol->string security-id-type)) "") "\0"
       security-id "\0"
       issuer-id "\0"))))

(define/contract executions-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]
                       [client-id integer?]
                       [account string?]
                       [timestamp (or/c moment? #f)]
                       [symbol string?]
                       [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                            'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f)]
                       [exchange string?]
                       [side (or/c 'buy 'sell 'sshort #f)]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 7]
               [version 3])
    (inherit-field msg-id version)
    (init-field [request-id 0]
                [client-id 0]
                [account ""]
                [timestamp #f]
                [symbol ""]
                [security-type #f]
                [exchange ""]
                [side #f])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (number->string request-id) "\0"
       (number->string client-id) "\0"
       account "\0"
       (if (moment? timestamp) (~t (adjust-timezone timestamp "UTC") "yyyyMMdd-HH:mm:ss") "") "\0"
       symbol "\0"
       (if (symbol? security-type) (string-upcase (symbol->string security-type)) "") "\0"
       exchange "\0"
       (if (symbol? side) (string-upcase (symbol->string side)) "") "\0"))))

(define/contract historical-data-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]
                       [contract-id integer?]
                       [symbol string?]
                       [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                            'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f)]
                       [expiry (or/c date? #f)]
                       [strike rational?]
                       [right (or/c 'call 'put #f)]
                       [multiplier (or/c rational? #f)]
                       [exchange string?]
                       [primary-exchange string?]
                       [currency string?]
                       [local-symbol string?]
                       [trading-class string?]
                       [include-expired boolean?]
                       [end-moment moment?]
                       [bar-size (or/c '1-secs '5-secs '15-secs '30-secs '1-min '2-mins '3-mins '5-mins '15-mins
                                       '30-mins '1-hour '2-hours '3-hours '4-hours '8-hours '1-day '1W '1M)]
                       [duration period?]
                       [use-rth boolean?]
                       [what-to-show (or/c 'trades 'midpoint 'bid 'ask 'bid-ask 'historical-volatility
                                           'option-implied-volatility 'fee-rate 'rebate-rate)]
                       [combo-legs (listof combo-leg?)]
                       [keep-up-to-date boolean?]
                       [chart-options string?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 20]
               [version 6])
    (inherit-field msg-id)
    (init-field [request-id 0]
                [contract-id 0]
                [symbol ""]
                [security-type #f]
                [expiry #f]
                [strike 0]
                [right #f]
                [multiplier #f]
                [exchange ""]
                [primary-exchange ""]
                [currency ""]
                [local-symbol ""]
                [trading-class ""]
                [include-expired #f]
                [end-moment (now/moment)]
                [bar-size '1-hour]
                [duration (days 1)]
                [use-rth #f]
                [what-to-show 'trades]
                [combo-legs (list)]
                [keep-up-to-date #f]
                [chart-options ""])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       ; version is unused for later server protocol versions
       (number->string request-id) "\0"
       (number->string contract-id) "\0"
       symbol "\0"
       (if (symbol? security-type) (string-upcase (symbol->string security-type)) "") "\0"
       (if (date? expiry) (~t expiry "yyyyMMdd") "") "\0"
       (real->decimal-string strike 2) "\0"
       (if (symbol? right) (string-upcase (substring (symbol->string right) 0 1)) "") "\0"
       (if (rational? multiplier) (number->string multiplier) "") "\0"
       exchange "\0"
       primary-exchange "\0"
       currency "\0"
       local-symbol "\0"
       trading-class "\0"
       (if include-expired "1" "0") "\0"
       (~t (adjust-timezone end-moment "UTC") "yyyyMMdd-HH:mm:ss") "\0"
       (string-replace (symbol->string bar-size) "-" " ") "\0"
       (cond [(time-period? duration)
              (string-append (number->string (+ (* 60 60 (period-ref duration 'hours))
                                                (* 60 (period-ref duration 'minutes))
                                                (period-ref duration 'seconds)))
                             " S")]
             [(date-period? duration)
              (string-append (number->string (+ (* 365 (period-ref duration 'years))
                                                (* 30 (period-ref duration 'months))
                                                (* 7 (period-ref duration 'weeks))
                                                (period-ref duration 'days)))
                             " D")]) "\0"
       (if use-rth "1" "0") "\0"
       (string-replace (string-upcase (symbol->string what-to-show)) "-" "_") "\0"
       ; format-date is a parameter for the Java API, but we are ignoring it. clients will receive a moment object
       ; that can be converted to a string or 'seconds since epoch' value
       "1" "\0" ; format-date
       (if (equal? 'bag security-type)
           (string-append
            (number->string (length combo-legs)) "\0"
            (apply string-append
                   (map (λ (cl) (string-append (number->string (combo-leg-contract-id cl)) "\0"
                                               (number->string (combo-leg-ratio cl)) "\0"
                                               (string-upcase (symbol->string (combo-leg-action cl))) "\0"
                                               (combo-leg-exchange cl) "\0"))
                        combo-legs)))
           "")
       (if keep-up-to-date "1" "0") "\0"
       chart-options "\0"))))

(define/contract historical-ticks-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]
                       [contract-id integer?]
                       [symbol string?]
                       [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                            'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f)]
                       [expiry (or/c date? #f)]
                       [strike rational?]
                       [right (or/c 'call 'put #f)]
                       [multiplier (or/c rational? #f)]
                       [exchange string?]
                       [primary-exchange string?]
                       [currency string?]
                       [local-symbol string?]
                       [trading-class string?]
                       [include-expired boolean?]
                       [start-moment moment?]
                       [end-moment moment?]
                       [number-of-ticks integer?]
                       [what-to-show (or/c 'midpoint 'bid-ask 'trades)]
                       [use-rth boolean?]
                       [ignore-size boolean?]
                       [misc-options (listof string?)]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 96]
               [version 0])
    (inherit-field msg-id version)
    (init-field [request-id 0]
                [contract-id 0]
                [symbol ""]
                [security-type #f]
                [expiry #f]
                [strike 0]
                [right #f]
                [multiplier #f]
                [exchange ""]
                [primary-exchange ""]
                [currency ""]
                [local-symbol ""]
                [trading-class ""]
                [include-expired #f]
                [start-moment (now/moment)]
                [end-moment (now/moment)]
                [number-of-ticks 1]
                [what-to-show 'midpoint]
                [use-rth #f]
                [ignore-size #f]
                [misc-options (list)])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       ; version is unused for this request message
       (number->string request-id) "\0"
       (number->string contract-id) "\0"
       symbol "\0"
       (if (symbol? security-type) (string-upcase (symbol->string security-type)) "") "\0"
       (if (date? expiry) (~t expiry "yyyyMMdd") "") "\0"
       (real->decimal-string strike 2) "\0"
       (if (symbol? right) (string-upcase (substring (symbol->string right) 0 1)) "") "\0"
       (if (rational? multiplier) (number->string multiplier) "") "\0"
       exchange "\0"
       primary-exchange "\0"
       currency "\0"
       local-symbol "\0"
       trading-class "\0"
       (if include-expired "1" "0") "\0"
       (~t (adjust-timezone start-moment "UTC") "yyyyMMdd-HH:mm:ss") "\0"
       (~t (adjust-timezone end-moment "UTC") "yyyyMMdd-HH:mm:ss") "\0"
       (number->string number-of-ticks) "\0"
       (string-replace (string-upcase (symbol->string what-to-show)) "-" "_") "\0"
       (if use-rth "1" "0") "\0"
       (if ignore-size "1" "0") "\0"
       "\0" ; misc-options is 'reserved for internal use'
       ))))

(define/contract market-data-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [request-id integer?]
                       [contract-id integer?]
                       [symbol string?]
                       [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                            'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f)]
                       [expiry (or/c date? #f)]
                       [strike rational?]
                       [right (or/c 'call 'put #f)]
                       [multiplier (or/c rational? #f)]
                       [exchange string?]
                       [primary-exchange string?]
                       [currency string?]
                       [local-symbol string?]
                       [trading-class string?]
                       [combo-legs (listof combo-leg?)]
                       [delta-neutral-contract-id (or/c integer? #f)]
                       [delta-neutral-delta (or/c rational? #f)]
                       [delta-neutral-price (or/c rational? #f)]
                       [generic-tick-list (listof symbol?)]
                       [snapshot boolean?]
                       [regulatory-snapshot boolean?]
                       [market-data-options string?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 1]
               [version 11])
    (inherit-field msg-id version)
    (init-field [request-id 0]
                [contract-id 0]
                [symbol ""]
                [security-type #f]
                [expiry #f]
                [strike 0]
                [right #f]
                [multiplier #f]
                [exchange ""]
                [primary-exchange ""]
                [currency ""]
                [local-symbol ""]
                [trading-class ""]
                [combo-legs (list)]
                [delta-neutral-contract-id #f]
                [delta-neutral-delta #f]
                [delta-neutral-price #f]
                [generic-tick-list (list)]
                [snapshot #f]
                [regulatory-snapshot #f]
                [market-data-options ""])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (number->string request-id) "\0"
       (number->string contract-id) "\0"
       symbol "\0"
       (if (symbol? security-type) (string-upcase (symbol->string security-type)) "") "\0"
       (if (date? expiry) (~t expiry "yyyyMMdd") "") "\0"
       (real->decimal-string strike 2) "\0"
       (if (symbol? right) (string-upcase (substring (symbol->string right) 0 1)) "") "\0"
       (if (rational? multiplier) (number->string multiplier) "") "\0"
       exchange "\0"
       primary-exchange "\0"
       currency "\0"
       local-symbol "\0"
       trading-class "\0"
       (if (equal? 'bag security-type)
           (string-append
            (number->string (length combo-legs)) "\0"
            (apply string-append
                   (map (λ (cl) (string-append (number->string (combo-leg-contract-id cl)) "\0"
                                               (number->string (combo-leg-ratio cl)) "\0"
                                               (string-upcase (symbol->string (combo-leg-action cl))) "\0"
                                               (combo-leg-exchange cl) "\0"))
                        combo-legs)))
           "")
       (if (and (integer? delta-neutral-contract-id)
                (rational? delta-neutral-delta)
                (rational? delta-neutral-price))
           (string-append
            "1" "\0"
            (number->string delta-neutral-contract-id) "\0"
            (real->decimal-string delta-neutral-delta 2) "\0"
            (real->decimal-string delta-neutral-price 2))
           "0")
       "\0"
       (string-join (map (λ (tick) (number->string (hash-ref generic-tick-request-hash tick))) generic-tick-list) ",") "\0"
       (if snapshot "1" "0") "\0"
       (if regulatory-snapshot "1" "0") "\0"
       market-data-options "\0"))))

(define/contract market-data-type-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [market-data-type (or/c 'real-time 'frozen 'delayed 'delayed-frozen)]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 59]
               [version 1])
    (inherit-field msg-id version)
    (init-field [market-data-type 'real-time])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (match market-data-type
         ['real-time "1"]
         ['frozen "2"]
         ['delayed "3"]
         ['delayed-frozen "4"]) "\0"))))

(define/contract open-orders-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 5]
               [version 1])
    (inherit-field msg-id version)
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"))))

(define/contract place-order-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [order-id integer?]
                       [contract-id integer?]
                       [symbol string?]
                       [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd 'fop 'war 'iopt 'fwd 'bag
                                            'ind 'bill 'fund 'fixed 'slb 'news 'cmdty 'bsk 'icu 'ics #f)]
                       [expiry (or/c date? #f)]
                       [strike rational?]
                       [right (or/c 'call 'put #f)]
                       [multiplier (or/c rational? #f)]
                       [exchange string?]
                       [primary-exchange string?]
                       [currency string?]
                       [local-symbol string?]
                       [trading-class string?]
                       [security-id-type (or/c 'cusip 'sedol 'isin 'ric #f)]
                       [security-id string?]
                       [action (or/c 'buy 'sell 'sshort)]
                       [total-quantity rational?]
                       [order-type string?]
                       [limit-price (or/c rational? #f)]
                       [aux-price (or/c rational? #f)]
                       [time-in-force (or/c 'day 'gtc 'opg 'ioc 'gtd 'gtt 'auc 'fok 'gtx 'dtc)]
                       [oca-group string?]
                       [account string?]
                       [open-close (or/c 'open 'close)]
                       [origin (or/c 'customer 'firm)]
                       [order-ref string?]
                       [transmit boolean?]
                       [parent-id integer?]
                       [block-order boolean?]
                       [sweep-to-fill boolean?]
                       [display-size integer?]
                       [trigger-method integer?]
                       [outside-rth boolean?]
                       [hidden boolean?]
                       [combo-legs (listof combo-leg?)]
                       [order-combo-legs (listof rational?)]
                       [smart-combo-routing-params hash?]
                       [discretionary-amount (or/c rational? #f)]
                       [good-after-time (or/c moment? #f)]
                       [good-till-date (or/c date? #f)]
                       [advisor-group string?]
                       [advisor-method string?]
                       [advisor-percentage string?]
                       [advisor-profile string?]
                       [model-code string?]
                       [short-sale-slot (or/c 0 1 2)]
                       [designated-location string?]
                       [exempt-code integer?]
                       [oca-type integer?]
                       [rule-80-a string?]
                       [settling-firm string?]
                       [all-or-none boolean?]
                       [minimum-quantity (or/c integer? #f)]
                       [percent-offset (or/c rational? #f)]
                       [electronic-trade-only boolean?]
                       [firm-quote-only boolean?]
                       [nbbo-price-cap (or/c rational? #f)]
                       [auction-strategy (or/c 'match 'improvement 'transparent #f)]
                       [starting-price rational?]
                       [stock-ref-price rational?]
                       [delta (or/c rational? #f)]
                       [stock-range-lower rational?]
                       [stock-range-upper rational?]
                       [override-percentage-constraints boolean?]
                       [volatility (or/c rational? #f)]
                       [volatility-type (or/c integer? #f)]
                       [delta-neutral-order-type string?]
                       [delta-neutral-aux-price (or/c rational? #f)]
                       [continuous-update integer?]
                       [reference-price-type (or/c integer? #f)]
                       [trailing-stop-price (or/c rational? #f)]
                       [trailing-percent (or/c rational? #f)]
                       [scale-init-level-size (or/c integer? #f)]
                       [scale-subs-level-size (or/c integer? #f)]
                       [scale-price-increment (or/c rational? #f)]
                       [scale-price-adjust-value (or/c rational? #f)]
                       [scale-price-adjust-interval (or/c integer? #f)]
                       [scale-profit-offset (or/c rational? #f)]
                       [scale-auto-reset boolean?]
                       [scale-init-position (or/c integer? #f)]
                       [scale-init-fill-quantity (or/c integer? #f)]
                       [scale-random-percent boolean?]
                       [scale-table string?]
                       [active-start-time string?]
                       [active-stop-time string?]
                       [hedge-type string?]
                       [hedge-param string?]
                       [opt-out-smart-routing boolean?]
                       [clearing-account string?]
                       [clearing-intent (or/c 'ib 'away 'pta #f)]
                       [not-held boolean?]
                       [delta-neutral-contract-id (or/c integer? #f)]
                       [delta-neutral-delta (or/c rational? #f)]
                       [delta-neutral-price (or/c rational? #f)]
                       [algo-strategy string?]
                       [algo-strategy-params hash?]
                       [algo-id string?]
                       [what-if boolean?]
                       [order-misc-options string?]
                       [solicited boolean?]
                       [randomize-size boolean?]
                       [randomize-price boolean?]
                       [reference-contract-id integer?]
                       [is-pegged-change-amount-decrease boolean?]
                       [pegged-change-amount rational?]
                       [reference-change-amount rational?]
                       [reference-exchange-id string?]
                       [conditions (listof condition?)]
                       [conditions-ignore-rth boolean?]
                       [conditions-cancel-order boolean?]
                       [adjusted-order-type (or/c 'mkt 'lmt 'stp 'stp-limit 'rel 'trail 'box-top 'fix-pegged 'lit 'lmt-+-mkt
                                                  'loc 'mit 'mkt-prt 'moc 'mtl 'passv-rel 'peg-bench 'peg-mid 'peg-mkt 'peg-prim
                                                  'peg-stk 'rel-+-lmt 'rel-+-mkt 'snap-mid 'snap-mkt 'snap-prim 'stp-prt
                                                  'trail-limit 'trail-lit 'trail-lmt-+-mkt 'trail-mit 'trail-rel-+-mkt 'vol
                                                  'vwap 'quote 'ppv 'pdv 'pmv 'psv #f)]
                       [trigger-price rational?]
                       [limit-price-offset rational?]
                       [adjusted-stop-price rational?]
                       [adjusted-stop-limit-price rational?]
                       [adjusted-trailing-amount rational?]
                       [adjusted-trailing-unit integer?]
                       [ext-operator string?]
                       [soft-dollar-tier-name string?]
                       [soft-dollar-tier-value string?]
                       [cash-quantity rational?]
                       [mifid2-decision-maker string?]
                       [mifid2-decision-algo string?]
                       [mifid2-execution-trader string?]
                       [mifid2-execution-algo string?]
                       [dont-use-auto-price-for-hedge boolean?]
                       [is-oms-container boolean?]
                       [discretionary-up-to-limit-price boolean?]
                       [use-price-management-algo boolean?]
                       [duration integer?]
                       [post-to-ats integer?]
                       [auto-cancel-parent boolean?]
                       [advanced-error-override string?]
                       [manual-order-time string?]
                       [minimum-trade-quantity (or/c integer? #f)]
                       [minimum-compete-size (or/c integer? #f)]
                       [compete-against-best-offset (or/c rational? #f)]
                       [is-compete-against-best-offset-up-to-mid boolean?]
                       [mid-offset-at-whole (or/c rational? #f)]
                       [mid-offset-at-half (or/c rational? #f)]
                       [customer-account string?]
                       [professional-customer boolean?]
                       [external-user-id string?]
                       [manual-order-indicator integer?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 3]
               [version 45])
    (inherit-field msg-id version)
    (init-field [order-id 0]
                [contract-id 0]
                [symbol ""]
                [security-type #f]
                [expiry #f]
                [strike 0]
                [right #f]
                [multiplier #f]
                [exchange ""]
                [primary-exchange ""]
                [currency ""]
                [local-symbol ""]
                [trading-class ""]
                [security-id-type #f]
                [security-id ""]
                ; default from Order
                [action 'buy]
                [total-quantity 0]
                ; default from Order
                [order-type "LMT"]
                [limit-price #f]
                [aux-price #f]
                ; default from Order
                [time-in-force 'day]
                [oca-group ""]
                [account ""]
                ; default from Order
                [open-close 'open]
                [origin 'customer]
                [order-ref ""]
                ; default from Order
                [transmit #t]
                [parent-id 0]
                [block-order #f]
                [sweep-to-fill #f]
                [display-size 0]
                [trigger-method 0]
                [outside-rth #f]
                [hidden #f]
                [combo-legs (list)]
                [order-combo-legs (list)]
                [smart-combo-routing-params (hash)]
                [discretionary-amount #f]
                [good-after-time #f]
                [good-till-date #f]
                [advisor-group ""]
                [advisor-method ""]
                [advisor-percentage ""]
                [advisor-profile ""]
                [model-code ""]
                [short-sale-slot 0]
                [designated-location ""]
                [exempt-code -1]
                [oca-type 0]
                [rule-80-a ""]
                [settling-firm ""]
                [all-or-none #f]
                [minimum-quantity #f]
                [percent-offset #f]
                [electronic-trade-only #f]
                [firm-quote-only #f]
                [nbbo-price-cap #f]
                [auction-strategy #f]
                [starting-price 0]
                [stock-ref-price 0]
                [delta #f]
                [stock-range-lower 0]
                [stock-range-upper 0]
                [override-percentage-constraints #f]
                [volatility #f]
                [volatility-type #f]
                [delta-neutral-order-type ""]
                [delta-neutral-aux-price #f]
                [continuous-update 0]
                [reference-price-type #f]
                [trailing-stop-price #f]
                [trailing-percent #f]
                [scale-init-level-size #f]
                [scale-subs-level-size #f]
                [scale-price-increment #f]
                [scale-price-adjust-value #f]
                [scale-price-adjust-interval #f]
                [scale-profit-offset #f]
                [scale-auto-reset #f]
                [scale-init-position #f]
                [scale-init-fill-quantity #f]
                [scale-random-percent #f]
                [scale-table ""]
                [active-start-time ""]
                [active-stop-time ""]
                [hedge-type ""]
                [hedge-param ""]
                [opt-out-smart-routing #f]
                [clearing-account ""]
                [clearing-intent #f]
                [not-held #f]
                [delta-neutral-contract-id #f]
                [delta-neutral-delta #f]
                [delta-neutral-price #f]
                [algo-strategy ""]
                [algo-strategy-params (hash)]
                [algo-id ""]
                [what-if #f]
                [order-misc-options ""]
                [solicited #f]
                [randomize-size #f]
                [randomize-price #f]
                [reference-contract-id 0]
                [is-pegged-change-amount-decrease #f]
                [pegged-change-amount 0]
                [reference-change-amount 0]
                [reference-exchange-id ""]
                [conditions (list)]
                [conditions-ignore-rth #f]
                [conditions-cancel-order #f]
                [adjusted-order-type #f]
                [trigger-price 0]
                [limit-price-offset 0]
                [adjusted-stop-price 0]
                [adjusted-stop-limit-price 0]
                [adjusted-trailing-amount 0]
                [adjusted-trailing-unit 0]
                [ext-operator ""]
                [soft-dollar-tier-name ""]
                [soft-dollar-tier-value ""]
                [cash-quantity 0]
                [mifid2-decision-maker ""]
                [mifid2-decision-algo ""]
                [mifid2-execution-trader ""]
                [mifid2-execution-algo ""]
                [dont-use-auto-price-for-hedge #f]
                [is-oms-container #f]
                [discretionary-up-to-limit-price #f]
                [use-price-management-algo #f]
                [duration 0]
                [post-to-ats 2147483647] ; Integer.MAX_VALUE
                [auto-cancel-parent #f]
                [advanced-error-override ""]
                [manual-order-time ""]
                [minimum-trade-quantity #f]
                [minimum-compete-size #f]
                [compete-against-best-offset #f]
                [is-compete-against-best-offset-up-to-mid #f]
                [mid-offset-at-whole #f]
                [mid-offset-at-half #f]
                [customer-account ""]
                [professional-customer #f]
                [external-user-id ""]
                [manual-order-indicator 0])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       ; (number->string version) "\0"
       (number->string order-id) "\0"
       (number->string contract-id) "\0"
       symbol "\0"
       (if (symbol? security-type) (string-upcase (symbol->string security-type)) "") "\0"
       (if (date? expiry) (~t expiry "yyyyMMdd") "") "\0"
       (real->decimal-string strike 2) "\0"
       (if (symbol? right) (string-upcase (substring (symbol->string right) 0 1)) "") "\0"
       (if (rational? multiplier) (number->string multiplier) "") "\0"
       exchange "\0"
       primary-exchange "\0"
       currency "\0"
       local-symbol "\0"
       trading-class "\0"
       (if (symbol? security-id-type) (string-upcase (symbol->string security-id-type)) "") "\0"
       security-id "\0"
       (string-upcase (symbol->string action)) "\0"
       (real->decimal-string total-quantity 2) "\0"
       order-type "\0"
       (if (rational? limit-price) (real->decimal-string limit-price 2) "") "\0"
       (if (rational? aux-price) (real->decimal-string aux-price 2) "") "\0"
       (string-upcase (symbol->string time-in-force)) "\0"
       oca-group "\0"
       account "\0"
       (string-upcase (substring (symbol->string open-close) 0 1)) "\0"
       (match origin
         ['customer "0"]
         ['firm "1"])
       "\0"
       order-ref "\0"
       (if transmit "1" "0") "\0"
       (number->string parent-id) "\0"
       (if block-order "1" "0") "\0"
       (if sweep-to-fill "1" "0") "\0"
       (number->string display-size) "\0"
       (number->string trigger-method) "\0"
       (if outside-rth "1" "0") "\0"
       (if hidden "1" "0") "\0"
       (if (equal? 'bag security-type)
           (string-append
            (number->string (length combo-legs)) "\0"
            (apply string-append
                   (map (λ (cl) (string-append (number->string (combo-leg-contract-id cl)) "\0"
                                               (number->string (combo-leg-ratio cl)) "\0"
                                               (string-upcase (symbol->string (combo-leg-action cl))) "\0"
                                               (combo-leg-exchange cl) "\0"
                                               (match (combo-leg-open-close cl)
                                                 ['same "0"]
                                                 ['open "1"]
                                                 ['close "2"]
                                                 [_ "3"]) "\0"
                                               (number->string (combo-leg-short-sale-slot cl)) "\0"
                                               (combo-leg-designated-location cl) "\0"
                                               (number->string (combo-leg-exempt-code cl)) "\0"))
                        combo-legs)))
           "")
       (if (equal? 'bag security-type)
           (string-append
            (number->string (length order-combo-legs)) "\0"
            (apply string-append
                   (map (λ (ocl) (string-append (number->string ocl) "\0"))
                        order-combo-legs)))
           "")
       (if (equal? 'bag security-type)
           (string-append
            (number->string (hash-count smart-combo-routing-params)) "\0"
            (apply string-append
                   (hash-map smart-combo-routing-params
                             (λ (k v) (string-append k "\0" v "\0")))))
           "")
       ; deprecated shares-allocation
       "\0"
       (if (rational? discretionary-amount) (real->decimal-string discretionary-amount 2) "") "\0"
       (if (moment? good-after-time) (~t (adjust-timezone good-after-time "UTC") "yyyyMMdd-HH:mm:ss") "") "\0"
       (if (date? good-till-date) (~t good-till-date "yyyyMMdd") "") "\0"
       advisor-group "\0"
       advisor-method "\0"
       advisor-percentage "\0"
       ; deprecated advisor-profile
       model-code "\0"
       (number->string short-sale-slot) "\0"
       designated-location "\0"
       (number->string exempt-code) "\0"
       (number->string oca-type) "\0"
       rule-80-a "\0"
       settling-firm "\0"
       (if all-or-none "1" "0") "\0"
       (if (integer? minimum-quantity) (number->string minimum-quantity) "") "\0"
       (if (rational? percent-offset) (real->decimal-string percent-offset 2) "") "\0"
       (if electronic-trade-only "1" "0") "\0" ; latest Java client versions just send #f
       (if firm-quote-only "1" "0") "\0" ; latest Java client versions just send #f
       (if (rational? nbbo-price-cap) (real->decimal-string nbbo-price-cap 2) "") "\0" ; latest Java client versions just send max value
       (match auction-strategy
         ['match "1"]
         ['improvement "2"]
         ['transparent "3"]
         [_ "0"]) "\0"
       (real->decimal-string starting-price 2) "\0"
       (real->decimal-string stock-ref-price 2) "\0"
       (if (rational? delta) (real->decimal-string delta 2) "") "\0"
       (real->decimal-string stock-range-lower 2) "\0"
       (real->decimal-string stock-range-upper 2) "\0"
       (if override-percentage-constraints "1" "0") "\0"
       (if (rational? volatility) (real->decimal-string (* 100 volatility) 2) "") "\0"
       (if (integer? volatility-type) (number->string volatility-type) "") "\0"
       ; there is some additional logic surrounding the delta neutral order type but
       ; it is currently unknown how to properly construct it, so we'll send nothing
       "" "\0"
       (if (rational? delta-neutral-aux-price) (real->decimal-string delta-neutral-aux-price 2) "") "\0"
       (number->string continuous-update) "\0"
       (if (integer? reference-price-type) (number->string reference-price-type) "") "\0"
       (if (rational? trailing-stop-price) (real->decimal-string trailing-stop-price 2) "") "\0"
       (if (rational? trailing-percent) (real->decimal-string (* 100 trailing-percent) 2) "") "\0"
       (if (integer? scale-init-level-size) (number->string scale-init-level-size) "") "\0"
       (if (integer? scale-subs-level-size) (number->string scale-subs-level-size) "") "\0"
       (if (rational? scale-price-increment)
           (string-append
            (real->decimal-string scale-price-increment 2) "\0"
            (if (rational? scale-price-adjust-value) (real->decimal-string scale-price-adjust-value 2) "") "\0"
            (if (integer? scale-price-adjust-interval) (number->string scale-price-adjust-interval) "") "\0"
            (if (rational? scale-profit-offset) (real->decimal-string scale-profit-offset 2) "") "\0"
            (if scale-auto-reset "1" "0") "\0"
            (if (integer? scale-init-position) (number->string scale-init-position) "") "\0"
            (if (integer? scale-init-fill-quantity) (number->string scale-init-fill-quantity) "") "\0"
            (if scale-random-percent "1" "0"))
           "\0")
       scale-table "\0"
       active-start-time "\0"
       active-stop-time "\0"
       ; there is some additional logic surrounding hedge type and hedge param but it is
       ; currently unknown which values are acceptable, so we'll send nothing
       "" "\0"
       (if opt-out-smart-routing "1" "0") "\0"
       clearing-account "\0"
       (match clearing-intent
         ['ib "IB"]
         ['away "Away"]
         ['pta "PTA"]
         [_ ""]) "\0"
       (if not-held "1" "0") "\0"
       (if (and (integer? delta-neutral-contract-id)
                (rational? delta-neutral-delta)
                (rational? delta-neutral-price))
           (string-append
            "1" "\0"
            (number->string delta-neutral-contract-id) "\0"
            (real->decimal-string delta-neutral-delta 2) "\0"
            (real->decimal-string delta-neutral-price 2))
           "0") "\0"
       algo-strategy "\0"
       (if (equal? "" algo-strategy)
           ""
           (string-append
            (number->string (hash-count algo-strategy-params)) "\0"
            (apply string-append
                   (hash-map algo-strategy-params
                             (λ (k v) (string-append k "\0" v "\0"))))))
       algo-id "\0"
       (if what-if "1" "0") "\0"
       order-misc-options "\0"
       (if solicited "1" "0") "\0"
       (if randomize-size "1" "0") "\0"
       (if randomize-price "1" "0") "\0"
       (if (equal? "PEG BENCH" order-type)
           (string-append
            (number->string reference-contract-id) "\0"
            (if is-pegged-change-amount-decrease "1" "0") "\0"
            (real->decimal-string pegged-change-amount 2) "\0"
            (real->decimal-string reference-change-amount 2) "\0"
            reference-exchange-id "\0")
           "")
       (number->string (length conditions)) "\0"
       (if (< 0 (length conditions))
           (string-append
            (apply string-append
                   (map (λ (c)
                          (string-append
                           (match (condition-type c) ['price "1"] ['time "3"] ['margin "4"] ['execution "5"] ['volume "6"] ['percent-change "7"]) "\0"
                           (match (condition-boolean-operator c) ['and "a"] ['or "o"]) "\0"
                           (match (condition-type c)
                             ['price (string-append
                                      (match (condition-comparator c) ['less-than "0"] ['greater-than "1"]) "\0"
                                      (real->decimal-string (condition-value c) 2) "\0"
                                      (number->string (condition-contract-id c)) "\0"
                                      (condition-exchange c) "\0"
                                      (match (condition-trigger-method c)
                                        ['default "0"]
                                        ['double-bid/ask "1"]
                                        ['last "2"]
                                        ['double-last "3"]
                                        ['bid/ask "4"]
                                        ['last-of-bid/ask "7"]
                                        ['mid-point "8"]) "\0")]
                             ['time (string-append
                                     (match (condition-comparator c) ['less-than "0"] ['greater-than "1"]) "\0"
                                     (~t (adjust-timezone (condition-value c) "UTC") "yyyyMMdd-HH:mm:ss") "\0")]
                             ['margin (string-append
                                       (match (condition-comparator c) ['less-than "0"] ['greater-than "1"]) "\0"
                                       (number->string (condition-value c)) "\0")]
                             ['execution (string-append
                                          (string-upcase (symbol->string (condition-security-type c))) "\0"
                                          (condition-exchange c) "\0"
                                          (condition-symbol c) "\0")]
                             ['volume (string-append
                                       (match (condition-comparator c) ['less-than "0"] ['greater-than "1"]) "\0"
                                       (number->string (condition-value c)) "\0"
                                       (number->string (condition-contract-id c)) "\0"
                                       (condition-exchange c) "\0")]
                             ['percent-change (string-append
                                               (match (condition-comparator c) ['less-than "0"] ['greater-than "1"]) "\0"
                                               (real->decimal-string (condition-value c) 2) "\0"
                                               (number->string (condition-contract-id c)) "\0"
                                               (condition-exchange c) "\0")])))
                        conditions))
            (if conditions-ignore-rth "1" "0") "\0"
            (if conditions-cancel-order "1" "0") "\0")
           "")
       (if (symbol? adjusted-order-type)
           (string-replace (string-upcase (symbol->string order-type)) "-" " ")
           "") "\0"
       (real->decimal-string trigger-price 2) "\0"
       (real->decimal-string limit-price-offset 2) "\0"
       (real->decimal-string adjusted-stop-price 2) "\0"
       (real->decimal-string adjusted-stop-limit-price 2) "\0"
       (real->decimal-string adjusted-trailing-amount 2) "\0"
       (number->string adjusted-trailing-unit) "\0"
       ext-operator "\0"
       soft-dollar-tier-name "\0"
       soft-dollar-tier-value "\0"
       (real->decimal-string cash-quantity 2) "\0"
       mifid2-decision-maker "\0"
       mifid2-decision-algo "\0"
       mifid2-execution-trader "\0"
       mifid2-execution-algo "\0"
       (if dont-use-auto-price-for-hedge "1" "0") "\0"
       (if is-oms-container "1" "0") "\0"
       (if discretionary-up-to-limit-price "1" "0") "\0"
       (if use-price-management-algo "1" "0") "\0"
       (number->string duration) "\0"
       (number->string post-to-ats) "\0"
       (if auto-cancel-parent "1" "0") "\0"
       advanced-error-override "\0"
       manual-order-time "\0"
       (if (equal? "IBKRATS" exchange)
           (string-append (if (integer? minimum-trade-quantity) (number->string minimum-trade-quantity)
                              "") "\0")
           "")
       (if (equal? "PEG BEST" order-type)
           (string-append (if (integer? minimum-compete-size) (number->string minimum-compete-size)
                              "") "\0"
                          (if (rational? compete-against-best-offset) (real->decimal-string compete-against-best-offset 2)
                              "") "\0")
           "")
       (if (or (and (equal? "PEG BEST" order-type) is-compete-against-best-offset-up-to-mid)
               (equal? "PEG MID" order-type))
           (string-append (if (rational? mid-offset-at-whole) (real->decimal-string mid-offset-at-whole 2)
                              "") "\0"
                          (if (rational? mid-offset-at-half) (real->decimal-string mid-offset-at-half 2)
                              "") "\0")
           "")
       customer-account "\0"
       (if professional-customer "1" "0") "\0"
       external-user-id "\0"
       (number->string manual-order-indicator) "\0"))))

(define/contract start-api-req%
  (class/c (inherit-field [msg-id integer?]
                          [version integer?])
           (init-field [client-id integer?]))
  (class* ibkr-msg%
    (req-msg<%>)
    (super-new [msg-id 71]
               [version 2])
    (inherit-field msg-id version)
    (init-field [client-id 0])
    (define/public (->string)
      (string-append
       (number->string msg-id) "\0"
       (number->string version) "\0"
       (number->string client-id) "\0"
       ; optional capabilities not used currently
       "\0"))))
