#lang scribble/manual

@title{Interactive Brokers API}
@author{evdubs}

Racket implementation for the @link["https://ibkrcampus.com/campus/ibkr-api-page/twsapi-doc/"]{Interactive Brokers' Trader Workstation Client API}.

This implementation is based on the Java TWS API version 10.30.01. The protocol used to communicate between the client and server establishes
 the client version and should allow the server to continue consuming and producing messages compatible with our version even when the server
 is updated. However, when there are desirable new features added, this library may be updated and its version number updated to reflect
 the version of the TWS API the new code uses.

The overall design of this library is to use objects to represent the connection and request messages and to use structs to represent
 response messages. Using objects for the connection and request messages seemed to make the process of creation easier as there are many
 fields that are often not cared about and can be omitted. We also use an interface and a base class for request messages. For response
 message, we stick to structs as we don't care about inheritance, nor do we need an ease-of-use creation method as the library creates
 the fully-filled-in instances. This is maybe a weird design.

With the release of Debian Trixie in early August 2025, it was noticed that older timezones like "US/Eastern" were no longer supplied
 in the default operating system `zoneinfo` files, even though IBKR uses them. If you have errors like:

"Unable to match pattern [VV] against input "US/Eastern" [,bt for context]"

then you may need to install a package like `tzdata-legacy` for these older timezones.

@(require racket/class
          racket/contract)
@(require (for-label racket/base
                     racket/class
		     racket/contract
		     racket/list
		     racket/bool))
@(provide (for-label (all-from-out racket/base
                                   racket/class
				   racket/contract
				   racket/list
				   racket/bool)))

@section{Establishing a connection}

@defmodule[interactive-brokers-api]

The general code flow to establish a (default) connection and send a message is as follows:

@#reader scribble/comment-reader
(racketblock
 (define ibkr (new ibkr-session%))
 (send ibkr connect)
 ;; The connection should be established after call to connect
 ;; Doing the below may be useful for testing
 (require interactive-brokers-api/request-messages)
 (send ibkr send-msg (new executions-req%))
)

@(require (for-label "base-structs.rkt"
                     "request-messages.rkt"
                     "response-messages.rkt"))

@defclass[ibkr-session% object% ()]{

This object is responsible for establishing a connection, sending messages, and registering callbacks to receive messages. One
 quirk of this implementation is that calls to @racket[send-msg] will block until we receive a response. During testing, it was
 seen that attempting to send multiple requests without waiting for a response forced a disconnect.

@defconstructor[([client-id integer? 0]
                 [handle-account-value-rsp (-> account-value-rsp? any) (λ (av) void)]
		 [handle-accounts-rsp (-> (listof string?) any) (λ (a) void)]
		 [handle-commission-report-rsp (-> commission-report-rsp? any) (λ (cr) void)]
		 [handle-contract-details-rsp (-> contract-details-rsp? any) (λ (cd) void)]
		 [handle-err-rsp (-> err-rsp? any) (λ (e) void)]
		 [handle-execution-rsp (-> execution-rsp? any) (λ (e) void)]
		 [handle-historical-data-rsp (-> historical-data-rsp? any) (λ (hd) void)]
		 [handle-market-data-rsp (-> market-data-rsp? any) (λ (md) void)]
		 [handle-next-valid-id-rsp (-> next-valid-id-rsp? any) (λ (nvi) void)]
		 [handle-open-order-rsp (-> open-order-rsp? any) (λ (oo) void)]
		 [handle-option-market-data-rsp (-> option-market-data-rsp? any) (λ (omd) void)]
		 [handle-order-status-rsp (-> order-status-rsp? any) (λ (os) void)]
		 [handle-portfolio-value-rsp (-> portfolio-value-rsp? any) (λ (pv) void)]
		 [handle-server-time-rsp (-> moment? any) (λ (st) void)]
		 [hostname string? "127.0.0.1"]
		 [port-no port-number? 7497]
		 [write-messages boolean? #f])]{

On construction, we attempt to connect to the TWS server from the specified @racket[hostname] and @racket[port-no]. Encryption is
 not used currently; this library is not recommended to be used over an unsecure network.

All response handlers will execute in the same, separate thread from the thread that constructs @racket[ibkr-session%].

The @racket[write-messages] field, when set to @racket[#t], will @racket[write] both request and response messages to the
 @racket[current-output-port].

}

@defmethod[(connect) void?]{

When called, a @racket[thread] is created to read from the socket and call the appropriate response handler with the received message.
 Currently, this thread will die when the connection is interruped. When this happens, I just create a new @racket[ibkr-session%] to
 connect again rather than attempt to call @racket[connect] on the existing session.
 
}

@defmethod[(send-msg [msg (is-a?/c req-msg<%>)]) void?]{}

Sends a message over the established session. See the @racket[request-messages] section for information on available request messages.

}

@section{Request messages}

@defmodule[interactive-brokers-api/request-messages]

@subsection{Base interface and class}

@definterface[req-msg<%> ()]{

This interface makes sure all request messages provide a @racket[->string] method that can be used to serialize the object into a
 string that can be processed by the server.

@defmethod[(->string) string?]{}

}

@defclass[ibkr-msg% object% ()]{

This is the base class for all request messages. There is no need for a client of this library to instantiate this class. This
 class is just a declaration that each request message will contain a @racket[msg-id] and @racket[version].

@defconstructor[([msg-id integer?]
                 [version integer?])]{}

}

@subsection{Account Data}

@defclass[account-data-req% ibkr-msg% (req-msg<%>)]{

Request message to receive @racket[account-value-rsp]s and @racket[portfolio-value-rsp]s. Each component of an account (e.g Net
 Liquidation, Account Code, Cash Balance, etc.) will be received in an individual response; there is no large structure or map
 that will be returned that has all of the account components. Likewise for the components of a portfolio. If you wish to aggregate
 the account and portfolio components, you will need to do that in your own application code. To receive account data, do:

@racketblock[
(send ibkr send-msg (new account-data-req% [subscribe #t]))
]

By default @racket[subscribe] is @racket[#f]. To actually subscribe to data, you will need to set this value to @racket[#t]. When
 you are finished consuming account data, you can do the following to unsubscribe:

@racketblock[
(send ibkr send-msg (new account-data-req% [subscribe #f]))
]

@defconstructor[([subscribe boolean? #f]
                 [account-code string? ""])]

}

@subsection{Contract Details}

@defclass[contract-details-req% ibkr-msg% (req-msg<%>)]{

Request message to receive a @racket[contract-details-rsp]. Here, if there is any ambiguity in your request, you will receive all of
 the contract details that match your request. As an example,

@racketblock[
(send ibkr send-msg
      (new contract-details-req% [symbol "AAPL"]
                                 [security-type 'opt]
				 [strike 200.0]))
]

will retrieve all actively trading AAPL options with a strike price of 200.0. By filling in more fields in your request, you are more
 likely to retrieve a single result if that is your objective.

@defconstructor[([request-id integer? 0]
                 [contract-id integer? 0]
                 [symbol string? ""]
                 [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		 		      'fop 'war 'iopt 'fwd 'bag 'ind
				      'bill 'fund 'fixed 'slb 'news 'cmdty
				      'bsk 'icu 'ics #f) #f]
                 [expiry (or/c date? #f) #f]
		 [strike rational? 0]
		 [right (or/c 'call 'put #f) #f]
		 [multiplier (or/c rational? #f) #f]
		 [exchange string? ""]
		 [primary-exchange string? ""]
		 [currency string? ""]
		 [local-symbol string? ""]
		 [trading-class string? ""]
                 [security-id-type (or/c 'cusip 'sedol 'isin 'ric #f) #f]
                 [security-id string? ""]
                 [issuer-id string? ""])]{}

}

@subsection{Executions (otherwise known as trades)}

@defclass[executions-req% ibkr-msg% (req-msg<%>)]{

Request message to receive @racket[execution-rsp]s. As an example,

@racketblock[
(send ibkr send-msg (new executions-req%
                         [timestamp (-period (now/moment) (days 7))]))
]

will retrieve all executions within a week.

@defconstructor[([request-id integer? 0]
                 [client-id integer? 0]
                 [account string? ""]
                 [timestamp (or/c moment? #f) #f]
                 [symbol string? ""]
                 [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		 		      'fop 'war 'iopt 'fwd 'bag 'ind
				      'bill 'fund 'fixed 'slb 'news 'cmdty
				      'bsk 'icu 'ics #f) #f]
                 [exchange string? ""]
                 [side (or/c 'buy 'sell 'sshort #f) #f])]{}

}

@subsection{Historical Data}

@defclass[historical-data-req% ibkr-msg% (req-msg<%>)]{

Request message to receive @racket[historical-data-rsp]s. The interesting part of this response is the list of @racket[bar]s
 that are sent back and can be used for display in a chart. As an example,

@racketblock[
(send ibkr send-msg (new historical-data-req%
                         [request-id 22]
                         [symbol "UPS"]
			 [security-type 'stk]
			 [exchange "SMART"]))
]

will retrieve 1-hour (@racket[bar-size] default) open-high-low-close bars from yesterday to today
 (@racket[end-moment] and @racket[duration] defaults) representing trades (@racket[what-to-show] default).

As of 2020-09-03, the smallest set of data at the finest resolution is to request 1-second bars over a duration of 30
 seconds.

You will need to track the relationship between your request-id and your parameters as the returned @racket[historical-data-rsp]s
 will not have the symbol, security-type, etc. information.

@defconstructor[([request-id integer? 0]
                 [contract-id integer? 0]
                 [symbol string? ""]
                 [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		 		      'fop 'war 'iopt 'fwd 'bag 'ind
				      'bill 'fund 'fixed 'slb 'news 'cmdty
				      'bsk 'icu 'ics #f) #f]
                 [expiry (or/c date? #f) #f]
                 [strike rational? 0]
                 [right (or/c 'call 'put #f) #f]
                 [multiplier (or/c rational? #f) #f]
                 [exchange string? ""]
                 [primary-exchange string? ""]
                 [currency string? ""]
                 [local-symbol string? ""]
                 [trading-class string? ""]
                 [include-expired boolean? #f]
                 [end-moment moment? (now/moment)]
                 [bar-size (or/c '1-secs '5-secs '15-secs '30-secs '1-min
		                 '2-mins '3-mins '5-mins '15-mins
                                 '30-mins '1-hour '2-hours '3-hours
				 '4-hours '8-hours '1-day '1W '1M) '1-hour]
                 [duration period? (days 1)]
                 [use-rth boolean? #f]
                 [what-to-show (or/c 'trades 'midpoint 'bid 'ask 'bid-ask
		                     'historical-volatility 'option-implied-volatility
				     'fee-rate 'rebate-rate) 'trades]
                 [combo-legs (listof combo-leg?) (list)]
                 [keep-up-to-date boolean? #f]
                 [chart-options string? ""])]{}

}

@defclass[cancel-historical-data-req% ibkr-msg% (req-msg<%>)]{

Request message to stop receiving @racket[historical-data-rsp]s.

@defconstructor[([request-id integer? 0])]{}

}

@subsection{Historical Ticks}

@defclass[historical-ticks-req% ibkr-msg% (req-msg<%>)]{

Request message to receive @racket[historical-ticks-rsp]s. The returned list of @racket[historical-tick]s are used in TWS's
 Time and Sales list. As an example,

@racketblock[
(send ibkr send-msg (new historical-ticks-req%
                         [request-id 87]
			 [symbol "UPS"]
			 [security-type 'stk]
			 [exchange "SMART"]
			 [currency "USD"]))
]

You will need to track the relationship between your request-id and your parameters as the returned @racket[historical-ticks-rsp]s
 will not have the symbol, security-type, etc. information.

@defconstructor[([request-id integer? 0]
                 [contract-id integer? 0]
                 [symbol string? ""]
                 [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
				      'fop 'war 'iopt 'fwd 'bag 'ind
				      'bill 'fund 'fixed 'slb 'news 'cmdty
				      'bsk 'icu 'ics #f) #f]
                 [expiry (or/c date? #f) #f]
                 [strike rational? 0]
                 [right (or/c 'call 'put #f) #f]
                 [multiplier (or/c rational? #f) #f]
                 [exchange string? ""]
                 [primary-exchange string? ""]
                 [currency string? ""]
                 [local-symbol string? ""]
                 [trading-class string? ""]
                 [include-expired boolean? #f]
		 [start-moment moment? (now/moment)]
                 [end-moment moment? (now/moment)]
                 [number-of-ticks integer? 1]
                 [what-to-show (or/c 'midpoint 'bid-ask 'trades) 'midpoint]
                 [use-rth boolean? #f]
                 [ignore-size boolean? #f]
                 [misc-options (listof string?) (list)])]{}

@racket[misc-options] is currently reserved for IBKR internal use.

}

@subsection{Market Data}

@defclass[market-data-req% ibkr-msg% (req-msg<%>)]{

Request message to receive streaming @racket[market-data-rsp]s. As an example,

@racketblock[
(send ibkr send-msg (new market-data-req%
                         [request-id 23]
                         [symbol "UPS"]
			 [security-type 'stk]
			 [exchange "SMART"]))
]

will subscribe to (at least) bid/ask price and size updates.

You will need to track the relationship between your request-id and your parameters as the returned @racket[market-data-rsp]s
 will not have the symbol, security-type, etc. information.

When requesting market data for an option, you will also receive @racket[option-market-data-rsp]s.

See @racket[generic-tick-requests] for the symbols to use for @racket[generic-tick-list].

@defconstructor[([request-id integer? 0]
                 [contract-id integer? 0]
                 [symbol string? ""]
                 [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		 		      'fop 'war 'iopt 'fwd 'bag 'ind
				      'bill 'fund 'fixed 'slb 'news 'cmdty
				      'bsk 'icu 'ics #f) #f]
                 [expiry (or/c date? #f) #f]
                 [strike rational? 0]
                 [right (or/c 'call 'put #f) #f]
                 [multiplier (or/c rational? #f) #f]
                 [exchange string? ""]
                 [primary-exchange string? ""]
                 [currency string? ""]
                 [local-symbol string? ""]
                 [trading-class string? ""]
                 [combo-legs (listof combo-leg?) (list)]
                 [delta-neutral-contract-id (or/c integer? #f) #f]
                 [delta-neutral-delta (or/c rational? #f) #f]
                 [delta-neutral-price (or/c rational? #f) #f]
                 [generic-tick-list (listof symbol?) (list)]
                 [snapshot boolean? #f]
                 [regulatory-snapshot boolean? #f]
                 [market-data-options string? ""])]{}

}

@defclass[cancel-market-data-req% ibkr-msg% (req-msg<%>)]{

Request message to stop receiving @racket[market-data-rsp]s.

@defconstructor[([request-id integer? 0])]{}

}

@defclass[market-data-type-req% ibkr-msg% (req-msg<%>)]{

Request message to change the type of market data received using calls to @racket[market-data-req%].
As an example,

@racketblock[
(send ibkr send-msg (new market-data-type-req%
                         [market-data-type 'delayed-frozen]))
]

will allow subsequent @racket[market-data-req%] calls to first retrieve real-time market data if available;
if not, delayed market data will be retrieved; if delayed data is unavailable, delayed frozen
(last available market data) data will be retrieved.

Using @racket[market-data-type-req%] is useful when subscribing to market data using a demo account where
real-time data may not be supported.

@defconstructor[([market-data-type (or/c 'real-time 'frozen 'delayed 'delayed-frozen)
                                   'real-time])]{}

}

@subsection{Orders}

@defclass[open-orders-req% ibkr-msg% (req-msg<%>)]{

Request message to receive all @racket[open-order-rsp]s. There are no fields to provide here to filter for particular
 open orders.

@defconstructor[()]{}

}

@defclass[place-order-req% ibkr-msg% (req-msg<%>)]{

Request message to place an order. As you can see below, there are tons of different fields to produce an order that is
 as complex as you desire. Certain fields might interfere with others or be required by others. Despite this class'
 many fields, it is likely that you will just be doing something simple like the following:

@racketblock[
(send ibkr send-msg
      (new place-order-req% [symbol "AAPL"]
                            [security-type 'stk]
			    [exchange "SMART"]
			    [currency "USD"]
			    [action 'buy]
			    [total-quantity 100]
			    [limit-price 200.0]))
]

Any questions related to which fields do what should first consult the IBKR docs or IBKR themselves. The fields of this
 class are intended to exactly match those in the Java client library.

Be sure to add a handler for @racket[next-valid-id-rsp] in @racket[ibkr-session%] so that you don't run into any errors
 as a result of reusing an order ID. Order IDs are unique integers over the life of an account.

@defconstructor[([order-id integer? 0]
                 [contract-id integer? 0]
		 [symbol string? ""]
		 [security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		                      'fop 'war 'iopt 'fwd 'bag 'ind
				      'bill 'fund 'fixed 'slb 'news 'cmdty
				      'bsk 'icu 'ics #f) #f]
	         [expiry (or/c date? #f) #f]
		 [strike rational? 0]
		 [right (or/c 'call 'put #f) #f]
		 [multiplier (or/c rational? #f) #f]
		 [exchange string? ""]
		 [primary-exchange string? ""]
		 [currency string? ""]
		 [local-symbol string? ""]
		 [trading-class string? ""]
		 [security-id-type (or/c 'cusip 'sedol 'isin 'ric #f) #f]
		 [security-id string? ""]
		 [action (or/c 'buy 'sell 'sshort) 'buy]
		 [total-quantity rational? 0]
		 [order-type string? "LMT"]
		 [limit-price (or/c rational? #f) #f]
		 [aux-price (or/c rational? #f) #f]
		 [time-in-force (or/c 'day 'gtc 'opg 'ioc 'gtd 'gtt
		                      'auc 'fok 'gtx 'dtc) 'day]
		 [oca-group string? ""]
		 [account string? ""]
		 [open-close (or/c 'open 'close) 'open]
		 [origin (or/c 'customer 'firm) 'customer]
		 [order-ref string? ""]
		 [transmit boolean? #t]
		 [parent-id integer? 0]
		 [block-order boolean? #f]
		 [sweep-to-fill boolean? #f]
		 [display-size integer? 0]
		 [trigger-method integer? 0]
		 [outside-rth boolean? #f]
		 [hidden boolean? #f]
		 [combo-legs (listof combo-leg?) (list)]
		 [order-combo-legs (listof rational?) (list)]
		 [smart-combo-routing-params hash? (hash)]
		 [discretionary-amount (or/c rational? #f) #f]
		 [good-after-time (or/c moment? #f) #f]
		 [good-till-date (or/c date? #f) #f]
		 [advisor-group string? ""]
		 [advisor-method string? ""]
		 [advisor-percentage string? ""]
		 [advisor-profile string? ""]
		 [model-code string? ""]
		 [short-sale-slot (or/c 0 1 2) 0]
		 [designated-location string? ""]
		 [exempt-code integer? -1]
		 [oca-type integer? 0]
		 [rule-80-a string? ""]
		 [settling-firm string? ""]
		 [all-or-none boolean? #f]
		 [minimum-quantity (or/c integer? #f) #f]
		 [percent-offset (or/c rational? #f) #f]
		 [electronic-trade-only boolean? #f]
		 [firm-quote-only boolean? #f]
		 [nbbo-price-cap (or/c rational? #f) #f]
		 [auction-strategy (or/c 'match 'improvement 'transparent #f) #f]
		 [starting-price rational? 0]
		 [stock-ref-price rational? 0]
		 [delta (or/c rational? #f) #f]
		 [stock-range-lower rational? 0]
		 [stock-range-upper rational? 0]
		 [override-percentage-constraints boolean? #f]
		 [volatility (or/c rational? #f) #f]
		 [volatility-type (or/c integer? #f) #f]
		 [delta-neutral-order-type string? ""]
		 [delta-neutral-aux-price (or/c rational? #f) #f]
		 [continuous-update integer? 0]
		 [reference-price-type (or/c integer? #f) #f]
		 [trailing-stop-price (or/c rational? #f) #f]
		 [trailing-percent (or/c rational? #f) #f]
		 [scale-init-level-size (or/c integer? #f) #f]
		 [scale-subs-level-size (or/c integer? #f) #f]
		 [scale-price-increment (or/c rational? #f) #f]
		 [scale-price-adjust-value (or/c rational? #f) #f]
		 [scale-price-adjust-interval (or/c integer? #f) #f]
		 [scale-profit-offset (or/c rational? #f) #f]
		 [scale-auto-reset boolean? #f]
		 [scale-init-position (or/c integer? #f) #f]
		 [scale-init-fill-quantity (or/c integer? #f) #f]
		 [scale-random-percent boolean? #f]
		 [scale-table string? ""]
		 [active-start-time string? ""]
		 [active-stop-time string? ""]
		 [hedge-type string? ""]
		 [hedge-param string? ""]
		 [opt-out-smart-routing boolean? #f]
		 [clearing-account string? ""]
		 [clearing-intent (or/c 'ib 'away 'pta #f) #f]
		 [not-held boolean? #f]
		 [delta-neutral-contract-id (or/c integer? #f) #f]
		 [delta-neutral-delta (or/c rational? #f) #f]
		 [delta-neutral-price (or/c rational? #f) #f]
		 [algo-strategy string? ""]
		 [algo-strategy-params hash? (hash)]
		 [algo-id string? ""]
		 [what-if boolean? #f]
		 [order-misc-options string? ""]
		 [solicited boolean? #f]
		 [randomize-size boolean? #f]
		 [randomize-price boolean? #f]
		 [reference-contract-id integer? 0]
		 [is-pegged-change-amount-decrease boolean? #f]
		 [pegged-change-amount rational? 0]
		 [reference-change-amount rational? 0]
		 [reference-exchange-id string? ""]
		 [conditions (listof condition?) (list)]
		 [conditions-ignore-rth boolean? #f]
		 [conditions-cancel-order boolean? #f]
		 [adjusted-order-type (or/c 'mkt 'lmt 'stp 'stp-limit
		                            'rel 'trail 'box-top 'fix-pegged
					    'lit 'lmt-+-mkt 'loc 'mit
					    'mkt-prt 'moc 'mtl 'passv-rel
					    'peg-bench 'peg-mid 'peg-mkt 'peg-prim
					    'peg-stk 'rel-+-lmt 'rel-+-mkt 'snap-mid
					    'snap-mkt 'snap-prim 'stp-prt 'trail-limit
					    'trail-lit 'trail-lmt-+-mkt 'trail-mit
					    'trail-rel-+-mkt 'vol 'vwap 'quote 'ppv
					    'pdv 'pmv 'psv #f) #f]
		 [trigger-price rational? 0]
		 [limit-price-offset rational? 0]
		 [adjusted-stop-price rational? 0]
		 [adjusted-stop-limit-price rational? 0]
		 [adjusted-trailing-amount rational? 0]
		 [adjusted-trailing-unit integer? 0]
		 [ext-operator string? ""]
		 [soft-dollar-tier-name string? ""]
		 [soft-dollar-tier-value string? ""]
		 [cash-quantity rational? 0]
                 [mifid2-decision-maker string? ""]
                 [mifid2-decision-algo string? ""]
                 [mifid2-execution-trader string? ""]
                 [mifid2-execution-algo string? ""]
                 [dont-use-auto-price-for-hedge boolean? #f]
                 [is-oms-container boolean? #f]
                 [discretionary-up-to-limit-price boolean? #f]
                 [use-price-management-algo boolean? #f]
                 [duration integer? 0]
                 [post-to-ats integer? 2147483647]
                 [auto-cancel-parent boolean? #f]
                 [advanced-error-override string? ""]
                 [manual-order-time string? ""]
                 [minimum-trade-quantity (or/c integer? #f) #f]
                 [minimum-compete-size (or/c integer? #f) #f]
                 [compete-against-best-offset (or/c rational? #f) #f]
                 [is-compete-against-best-offset-up-to-mid boolean? #f]
                 [mid-offset-at-whole (or/c rational? #f) #f]
                 [mid-offset-at-half (or/c rational? #f) #f]
                 [customer-account string? ""]
                 [professional-customer boolean? #f]
                 [external-user-id string? ""]
                 [manual-order-indicator integer? 0])]{

Please note that the fields @racket[action], @racket[order-type], @racket[time-in-force], @racket[open-close], and @racket[origin]
 use defaults that are not the @racket[#f], @racket[0], or @racket[""] typical defaults. Also note that you need to manage
 @racket[order-id] on your own. If you do not supply an @racket[order-id], it will use 0 and you will likely get an error stating
 the order ID has already been used. @racket[post-to-ats] has a default value of @racket[2147483647], which matches Java's
 Integer.MAX_VALUE. The API typically uses these MAX_VALUEs as defaults; they used to take care to make sure the values were not
 sent over the wire, but that is no longer the case with these additional fields.

}}

@section{Response messages}

@defmodule[interactive-brokers-api/response-messages]

@defstruct[account-value-rsp
((key string?)
 (value string?)
 (currency string?)
 (account-name string?))]{

As with the Java API, @racket[value] here is often numeric, but we leave it as a string because this field is not guaranteed
 to be numeric.

}

@defstruct[commission-report-rsp
((execution-id string?)
 (commission rational?)
 (currency string?)
 (realized-pnl (or/c rational? #f))
 (yield (or/c rational? #f))
 (yield-redemption-date (or/c integer? #f)))]{

Commission reports are sent along with executions when calls are made to @racket[executions-req%].

}

@defstruct[contract-details-rsp
((request-id integer?)
 (symbol string?)
 (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		      'fop 'war 'iopt 'fwd 'bag 'ind
		      'bill 'fund 'fixed 'slb 'news 'cmdty
		      'bsk 'icu 'ics #f))
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
 (md-size-multiplier integer?)
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
 (underlying-security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
                                 'fop 'war 'iopt 'fwd 'bag
				 'ind 'bill 'fund 'fixed 'slb 'news
				 'cmdty 'bsk 'icu 'ics #f))
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
 (fund-asset-type (or/c 'money-market 'fixed-income 'multi-asset
                        'equity 'sector 'guaranteed 'alternative
                        'others #f))
 (ineligibility-reasons hash?))]{

When receiving contract details, it is often nice to use the @racket[contract-id] for subsequent new order or market data
requests as these identifiers are unique.

}

@defstruct[err-rsp
((id integer?)
 (error-code integer?)
 (error-msg string?)
 (advanced-order-reject string?))]{

Generic error message for incorrectly formed requests. Consult the Java API docs for more information. 

}

@defstruct[execution-rsp
((request-id integer?)
 (order-id integer?)
 (contract-id integer?)
 (symbol string?)
 (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		      'fop 'war 'iopt 'fwd 'bag 'ind
		      'bill 'fund 'fixed 'slb 'news 'cmdty
		      'bsk 'icu 'ics #f))
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
 (pending-price-revision boolean?))]{

It is recommended to periodically call @racket[executions-req%] to make sure you receive all of the executions that have occurred.

}

@defstruct[historical-data-rsp
((request-id integer?)
 (start-moment moment?)
 (end-moment moment?)
 (bars (listof bar?)))]{

Be sure to check for @racket[err-rsp]s if you are not receiving historical data when you expect to.

}

@defstruct[historical-ticks-rsp
((request-id integer?)
 (done boolean?)
 (ticks (listof historical-tick?)))]{

You may receive several responses before receiving the final response with @racket[done] set to @racket[#t].

}

@defstruct[market-data-rsp
((request-id integer?)
 (type symbol?)
 (value rational?))]{

More information about tick types can be found in the @link["https://ibkrcampus.com/campus/ibkr-api-page/twsapi-doc/#available-tick-types"]{IBKR Docs}.

}

@defstruct[next-valid-id-rsp
((order-id integer?))]{

This response should be saved locally so that calls to @racket[place-order-req%] can include this saved value. It is not recommended
 to just track order IDs independently of what the API is giving you. As a reminder, it is necessary to provide an order ID to
 @racket[place-order-req%].

}

@defstruct[open-order-rsp
((order-id integer?)
 (contract-id integer?)
 (symbol string?)
 (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		      'fop 'war 'iopt 'fwd 'bag 'ind
		      'bill 'fund 'fixed 'slb 'news 'cmdty
		      'bsk 'icu 'ics #f))
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
 (time-in-force (or/c 'day 'gtc 'opg 'ioc 'gtd 'gtt
		      'auc 'fok 'gtx 'dtc))
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
 (adjusted-order-type (or/c 'mkt 'lmt 'stp 'stp-limit
			    'rel 'trail 'box-top 'fix-pegged
			    'lit 'lmt-+-mkt 'loc 'mit
			    'mkt-prt 'moc 'mtl 'passv-rel
			    'peg-bench 'peg-mid 'peg-mkt 'peg-prim
			    'peg-stk 'rel-+-lmt 'rel-+-mkt 'snap-mid
			    'snap-mkt 'snap-prim 'stp-prt 'trail-limit
			    'trail-lit 'trail-lmt-+-mkt 'trail-mit
			    'trail-rel-+-mkt 'vol 'vwap 'quote 'ppv
			    'pdv 'pmv 'psv #f))
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
 (bond-accrued-interest (or/c rational? #f)))]{

This response is largely just telling you what you already provided to @racket[place-order-req%]. The fields of interest here
 are the generated @racket[client-id] and @racket[perm-id].

}

@defstruct[option-market-data-rsp
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
 (underlying-price rational?))]{

When you request market data for options, you will receive both @racket[market-data-rsp]s as well as this response struct.

}

@defstruct[order-status-rsp
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
 (market-cap-price rational?))]{

This response gives a useful summary of the status of an order as well as the amount filled and amount remaining.

}

@defstruct[portfolio-value-rsp
((contract-id integer?)
 (symbol string?)
 (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
		      'fop 'war 'iopt 'fwd 'bag 'ind
		      'bill 'fund 'fixed 'slb 'news 'cmdty
		      'bsk 'icu 'ics #f))
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
 (account-name string?))]{

These responses are returned alongside @racket[account-value-rsp]s when @racket[account-data-req%] messages are sent.

}

@section{Base Structs}

@defmodule[interactive-brokers-api/base-structs]

@defstruct[bar
((moment moment?)
 (open rational?)
 (high rational?)
 (low rational?)
 (close rational?)
 (volume integer?)
 (weighted-average-price rational?)
 (count integer?))]{

This struct is returned as part of a @racket[historical-data-rsp].

}

@defstruct[combo-leg
((contract-id integer?)
 (ratio integer?)
 (action (or/c 'buy 'sell 'sshort))
 (exchange string?)
 (open-close (or/c 'same 'open 'close #f))
 (short-sale-slot (or/c 0 1 2))
 (designated-location string?)
 (exempt-code integer?))]{

Use @racket[combo-leg] within @racket[place-order-req%] when you want to place a spread. This is commonly done for options
 and will work for many strategies. Note that you can only provide @racket[contract-id], which you can retrieve from
 @racket[contract-details-req%].

}

@defstruct[condition
((type (or/c 'price 'time 'margin
             'execution 'volume 'percent-change))
 (boolean-operator (or/c 'and 'or))
 (comparator (or/c 'less-than 'greater-than #f))
 (value (or/c rational? moment? #f))
 (contract-id (or/c integer? #f))
 (exchange (or/c string? #f))
 (trigger-method (or/c 'default 'double-bid/ask 'last 'double-last
                       'bid/ask 'last-of-bid/ask 'mid-point #f))
 (security-type (or/c 'stk 'opt 'fut 'cash 'bond 'cfd
                      'fop 'war 'iopt 'fwd 'bag 'ind
		      'bill 'fund 'fixed 'slb 'news 'cmdty
		      'bsk 'icu 'ics #f))
 (symbol (or/c string? #f)))]{

Use @racket[condition] within @racket[place-order-req%] when you want your order to either take effect or be canceled only
 when certain conditions are met.

@itemlist[
@item{@racket['price] conditions require: @racket[boolean-operator], @racket[comparator], @racket[value], @racket[contract-id],
 @racket[exchange], and @racket[trigger-method].}

@item{@racket['time] conditions require: @racket[boolean-operator], @racket[comparator], and @racket[value].}

@item{@racket['margin] conditions require: @racket[boolean-operator], @racket[comparator], and @racket[value].}

@item{@racket['execution] conditions require: @racket[boolean-operator], @racket[exchange], @racket[security-type], and @racket[symbol].}

@item{@racket['volume] conditions require: @racket[boolean-operator], @racket[comparator], @racket[value], @racket[contract-id],
 and @racket[exchange].}

@item{@racket['percent-change] conditions require: @racket[boolean-operator], @racket[comparator], @racket[value], @racket[contract-id],
 and @racket[exchange].}
]

Where fields are not required for a given condition type, they are not sent to the server and are effectively ignored.

}

@defstruct[historical-tick
((moment moment?)
 (price (or/c rational? #f))
 (size (or/c rational? #f))
 (exchange (or/c string? #f))
 (special-conditions (or/c string? #f))
 (past-limit boolean?)
 (unreported boolean?)
 (bid-price (or/c rational? #f))
 (bid-size (or/c rational? #f))
 (ask-price (or/c rational? #f))
 (ask-size (or/c rational? #f))
 (past-high boolean?)
 (past-low boolean?))]{

This struct is returned as part of a @racket[historical-ticks-rsp]. This struct encapsulates the three types of tick responses:
 midpoint, bid-ask, and trades. Bid/ask/past values will be @racket[#f] when requesting midpoint and trades ticks. Price/size/exch
 values will be @racket[#f] when requesting bid-ask ticks.

}

@defthing[generic-tick-requests list?
#:value '((option-volume 100)
          (option-open-interest 101)
          (average-option-volume 105)
          (implied-volatility 106)
          (historical-high-low-stats 165)
          (creditman-mark-price 220)
          (auction 225)
          (mark-price 232)
          (rt-volume 233)
          (inventory 236)
          (fundamentals 258)
          (news 292)
          (trade-count 293)
          (trade-rate 294)
          (volume-rate 295)
          (last-rth-trade 318)
          (rt-trade-volume 375)
          (rt-historical-volatility 411)
          (ib-dividends 456)
          (bond-factor-multiplier 460)
          (etf-nav-last 577)
          (ipo-price 586)
          (delayed-mark 587)
          (futures-open-interest 588)
          (short-term-volume 595)
          (etf-nav-high-low 614)
          (creditman-slow-mark-price 619)
          (etf-nav-frozen-last 623))]{

These are the symbols to use for @racket[market-data-req%]'s @racket[generic-tick-list].

More information about tick types can be found in the @link["https://ibkrcampus.com/campus/ibkr-api-page/twsapi-doc/#available-tick-types"]{IBKR Docs}.

}
