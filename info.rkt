#lang info

(define collection "interactive-brokers-api")

(define version "976.01.0")

(define deps (list "base"
                   "binaryio"
                   "gregor-lib"))

(define build-deps (list "racket-doc"
                         "scribble-lib"))

(define scribblings '(("interactive-brokers-api.scrbl" ())))
