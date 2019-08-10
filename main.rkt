#lang racket/base

(require binaryio
         racket/class
         racket/contract
         racket/match
         racket/tcp
         srfi/19 ; Time and Date Functions
         "request-messages.rkt"
         "response-messages.rkt")

(provide ibkr-session%)

(define (write-int32 val out)
  (write-integer val 4 #t out))

(define (read-int32 in)
  (read-integer 4 #t in))

; write the string val to out with an int32 prefix indicating the string size
(define (write-sized-str val out)
  (write-int32 (string-length val) out)
  (display val out))

; read in a byte string val from in with an int32 prefix indicating the string size
(define (read-sized-str in)
  (let ([len (read-int32 in)])
    (read-bytes* len in)))

(define/contract ibkr-session%
  (class/c (init-field [client-id integer?]
                       [handle-contract-details-rsp (-> contract-details-rsp? any)]
                       [handle-err-rsp (-> err-rsp? any)]
                       [handle-execution-rsp (-> execution-rsp? any)]
                       [handle-next-valid-id-rsp (-> next-valid-id-rsp? any)]
                       [handle-open-order-rsp (-> open-order-rsp? any)]
                       [hostname string?]
                       [port-no port-number?])
           [connect (->m void?)]
           [send-msg (->m (is-a?/c req-msg<%>) void?)])
  (class object%
    (super-new)
    (init-field [client-id 0]
                [handle-contract-details-rsp (λ (cd) void)]
                [handle-err-rsp (λ (e) void)]
                [handle-execution-rsp (λ (e) void)]
                [handle-next-valid-id-rsp (λ (nvi) void)]
                [handle-open-order-rsp (λ (oo) void)]
                [hostname "127.0.0.1"]
                [port-no 7497])
    
    ; there seem to be issues when we attempt to read from ibkr-in when we send several messages
    ; to ibkr-out before we receive the first message. this channel exists to make sure that we
    ; wait after each ibkr-out write to make sure we've at least received one response so that
    ; we can continue. the thread reading from ibkr-in will never block as it just calls try-get
    ; and not get.
    (define req-rsp-channel (make-channel))

    (define-values (ibkr-in ibkr-out) (tcp-connect hostname port-no))
    
    (define/public (connect)
      (file-stream-buffer-mode ibkr-in 'none)
      (file-stream-buffer-mode ibkr-out 'none)

      ; read from ibkr-in forever
      (thread
       (λ () (do ()
               (#f)
               (match (parse-msg (read-sized-str ibkr-in))
                 [(? contract-details-rsp? cd) (handle-contract-details-rsp cd)]
                 [(? err-rsp? e) (handle-err-rsp e)]
                 [(? execution-rsp? e) (handle-execution-rsp e)]
                 [(? next-valid-id-rsp? nvi) (handle-next-valid-id-rsp nvi)]
                 [(? open-order-rsp? oo) (handle-open-order-rsp oo)]
                 [msg (writeln msg)]
                 [_ (writeln "Can't process")])
               (channel-try-get req-rsp-channel))))

      ; EClient.sendV100APIHeader
      (display "API\u0000" ibkr-out)
      (write-sized-str "v100..106" ibkr-out)
      (channel-put req-rsp-channel #f)

      ; EClient.startAPI
      (write-sized-str (send (new start-api-req% [client-id client-id]) ->string) ibkr-out)
      (channel-put req-rsp-channel #f))

    (define/public (send-msg msg)
      (write-sized-str (send msg ->string) ibkr-out)
      (channel-put req-rsp-channel #f))))
