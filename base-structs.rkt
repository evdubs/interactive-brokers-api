#lang racket/base

(require racket/contract)

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
     (exempt-code integer?))]))

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
