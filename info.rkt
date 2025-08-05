#lang info

(define collection "interactive-brokers-api")

(define version "10.30.01")

(define deps (list "base"
                   "binaryio"
                   "gregor-lib"))

(define build-deps (list "racket-doc"
                         "scribble-lib"))

(define scribblings '(("interactive-brokers-api.scrbl" ())))

(define license 'Apache-2.0)
