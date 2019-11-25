#lang racket/base

(require gregor
         racket/contract)

(provide
 (contract-out
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
     (comparator (or/c 'less-than 'greater-than))
     (value (or/c rational? moment?))
     (contract-id (or/c integer? #f))
     (exchange (or/c string? #f))
     (trigger-method (or/c 'default 'double-bid/ask 'last 'double-last 'bid/ask 'last-of-bid/ask 'mid-point #f)))]))

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
   trigger-method)
  #:transparent)
