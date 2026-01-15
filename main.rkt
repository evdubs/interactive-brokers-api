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
                       [handle-account-value-rsp (-> account-value-rsp? any)]
                       [handle-accounts-rsp (-> (listof string?) any)]
                       [handle-commission-report-rsp (-> commission-report-rsp? any)]
                       [handle-contract-details-rsp (-> contract-details-rsp? any)]
                       [handle-err-rsp (-> err-rsp? any)]
                       [handle-execution-rsp (-> execution-rsp? any)]
                       [handle-historical-data-rsp (-> historical-data-rsp? any)]
                       [handle-historical-ticks-rsp (-> historical-ticks-rsp? any)]
                       [handle-market-data-rsp (-> market-data-rsp? any)]
                       [handle-next-valid-id-rsp (-> next-valid-id-rsp? any)]
                       [handle-open-order-rsp (-> open-order-rsp? any)]
                       [handle-option-market-data-rsp (-> option-market-data-rsp? any)]
                       [handle-order-status-rsp (-> order-status-rsp? any)]
                       [handle-portfolio-value-rsp (-> portfolio-value-rsp? any)]
                       [handle-server-time-rsp (-> moment? any)]
                       [hostname string?]
                       [port-no port-number?]
                       [write-messages boolean?])
           [connect (->m void?)]
           [send-msg (->m (is-a?/c req-msg<%>) void?)])
  (class object%
    (super-new)
    (init-field [client-id 0]
                [handle-account-value-rsp (λ (av) void)]
                [handle-accounts-rsp (λ (a) void)]
                [handle-commission-report-rsp (λ (cr) void)]
                [handle-contract-details-rsp (λ (cd) void)]
                [handle-err-rsp (λ (e) void)]
                [handle-execution-rsp (λ (e) void)]
                [handle-historical-data-rsp (λ (hd) void)]
                [handle-historical-ticks-rsp (λ (hd) void)]
                [handle-market-data-rsp (λ (md) void)]
                [handle-next-valid-id-rsp (λ (nvi) void)]
                [handle-open-order-rsp (λ (oo) void)]
                [handle-option-market-data-rsp (λ (omd) void)]
                [handle-order-status-rsp (λ (os) void)]
                [handle-portfolio-value-rsp (λ (pv) void)]
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
                      [_ (cond [write-messages (display "Received: ") (writeln (string-split (bytes->string/utf-8 str) "\0"))])]
                      [msg (parse-msg str)])
                 (cond
                   [(account-value-rsp? msg) (handle-account-value-rsp msg)]
                   [(commission-report-rsp? msg) (handle-commission-report-rsp msg)]
                   [(contract-details-rsp? msg) (handle-contract-details-rsp msg)]
                   [(moment? msg) (handle-server-time-rsp msg)]
                   [(err-rsp? msg) (handle-err-rsp msg)]
                   [(execution-rsp? msg) (handle-execution-rsp msg)]
                   [(historical-data-rsp? msg) (handle-historical-data-rsp msg)]
                   [(historical-ticks-rsp? msg) (handle-historical-ticks-rsp msg)]
                   [(market-data-rsp? msg) (handle-market-data-rsp msg)]
                   [(next-valid-id-rsp? msg) (handle-next-valid-id-rsp msg)]
                   [(open-order-rsp? msg) (handle-open-order-rsp msg)]
                   [(option-market-data-rsp? msg) (handle-option-market-data-rsp msg)]
                   [(order-status-rsp? msg) (handle-order-status-rsp msg)]
                   [(portfolio-value-rsp? msg) (handle-portfolio-value-rsp msg)]
                   ; we might want to just create an accounts structure that we can typecheck for
                   ; rather than have to regex match what we think account strings look like
                   [(and (list? msg)
                         (< 0 (length msg))
                         (foldl (λ (str res) (and res (regexp-match #rx"[A-Z]+[0-9]+" str))) #t msg))
                    (handle-accounts-rsp msg)]
                   [else (display "No handler defined for message: ") (writeln msg)]))
               (channel-try-get req-rsp-channel))))

      ; EClient.sendV100APIHeader
      (display "API\u0000" ibkr-out)
      (write-sized-str "v100..187" ibkr-out)
      (channel-put req-rsp-channel #f)

      ; EClient.startAPI
      (write-sized-str (send (new start-api-req% [client-id client-id]) ->string) ibkr-out)
      (channel-put req-rsp-channel #f))

    (define/public (send-msg msg)
      (cond [write-messages (display "Sending: ") (writeln (string-split (send msg ->string) "\0"))])
      (write-sized-str (send msg ->string) ibkr-out))))
