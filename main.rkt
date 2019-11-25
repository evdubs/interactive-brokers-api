#lang racket/base

(require binaryio
         gregor
         racket/class
         racket/contract
         racket/string
         racket/tcp
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
                       [handle-accounts-rsp (-> (listof string?) any)]
                       [handle-contract-details-rsp (-> contract-details-rsp? any)]
                       [handle-err-rsp (-> err-rsp? any)]
                       [handle-execution-rsp (-> execution-rsp? any)]
                       [handle-next-valid-id-rsp (-> next-valid-id-rsp? any)]
                       [handle-open-order-rsp (-> open-order-rsp? any)]
                       [handle-server-time-rsp (-> moment? any)]
                       [hostname string?]
                       [port-no port-number?]
                       [write-messages boolean?])
           [connect (->m void?)]
           [send-msg (->m (is-a?/c req-msg<%>) void?)])
  (class object%
    (super-new)
    (init-field [client-id 0]
                [handle-accounts-rsp (λ (a) void)]
                [handle-contract-details-rsp (λ (cd) void)]
                [handle-err-rsp (λ (e) void)]
                [handle-execution-rsp (λ (e) void)]
                [handle-next-valid-id-rsp (λ (nvi) void)]
                [handle-open-order-rsp (λ (oo) void)]
                [handle-server-time-rsp (λ (st) void)]
                [hostname "127.0.0.1"]
                [port-no 7497]
                [write-messages #f])
    
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
               (let* ([str (read-sized-str ibkr-in)]
                      [msg (parse-msg str)])
                 (cond [write-messages (display "Received: ") (writeln (string-split (bytes->string/utf-8 str) "\0"))])
                 (cond
                   [(contract-details-rsp? msg) (handle-contract-details-rsp msg)]
                   [(moment? msg) (handle-server-time-rsp msg)]
                   [(err-rsp? msg) (handle-err-rsp msg)]
                   [(execution-rsp? msg) (handle-execution-rsp msg)]
                   [(next-valid-id-rsp? msg) (handle-next-valid-id-rsp msg)]
                   [(open-order-rsp? msg) (handle-open-order-rsp msg)]
                   ; we might want to just create an accounts structure that we can typecheck for
                   ; rather than have to regex match what we think account strings look like
                   [(and (list? msg)
                         (< 0 (length msg))
                         (foldl (λ (str res) (and res (regexp-match #rx"[A-Z]+[0-9]+" str))) #t msg))
                    (handle-accounts-rsp msg)]
                   [else (writeln msg)]))
               (channel-try-get req-rsp-channel))))

      ; EClient.sendV100APIHeader
      (display "API\u0000" ibkr-out)
      (write-sized-str "v100..106" ibkr-out)
      (channel-put req-rsp-channel #f)

      ; EClient.startAPI
      (write-sized-str (send (new start-api-req% [client-id client-id]) ->string) ibkr-out)
      (channel-put req-rsp-channel #f))

    (define/public (send-msg msg)
      (cond [write-messages (display "Sending: ") (writeln (string-split (send msg ->string) "\0"))])
      (write-sized-str (send msg ->string) ibkr-out)
      (channel-put req-rsp-channel #f))))
