#lang scribble/manual

@title{Interactive Brokers API}
@author{evdubs}

Racket implementation for the @link["https://interactivebrokers.github.io/tws-api/"]{Interactive Brokers' Trader Workstation Client API}.

This implementation is based on the Java TWS API version 972.18. The protocol used to communicate between the client and server establishes
 the client version and should allow the server to continue consuming and producing messages compatible with our version even when the server
 is updated. However, when there are desirable new features added, this library may be updated and its version number updated to reflect
 the version of the TWS API the new code uses.

The overall design of this library is to use objects to represent the connection and request messages and to use structs to represent
 response messages. Using objects for the connection and request messages seemed to make the process of creation easier as there are many
 fields that are often not cared about and can be omitted. We also use an interface and a base class for request messages. For response
 message, we stick to structs as we don't care about inheritance, nor do we need an ease-of-use creation method as the library creates
 the fully-filled-in instances. This is maybe a weird design.

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

@defclass[ibkr-session% object% ()]{

This object is responsible for establishing a connection, sending messages, and registering callbacks to receive messages. One
 quirk of this implementation is that calls to @racket[send-msg] will block until we receive a response. During testing, it was
 seen that attempting to send multiple requests without waiting for a response forced a disconnect.

@defconstructor[([client-id integer? 0]
                 [handle-accounts-rsp (-> (listof string?) any) (λ (a) void)]
                 [handle-contract-details-rsp (-> contract-details-rsp? any) (λ (a) void)]
                 [handle-err-rsp (-> err-rsp? any) (λ (a) void)]
                 [handle-execution-rsp (-> execution-rsp? any) (λ (a) void)]
                 [handle-next-valid-id-rsp (-> next-valid-id-rsp? any) (λ (a) void)]
                 [handle-open-order-rsp (-> open-order-rsp? any) (λ (a) void)]
                 [handle-server-time-rsp (-> moment? any) (λ (a) void)]
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

@subsection{Contract Details}

@(require (for-label "request-messages.rkt"))

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
                 [security-id string? ""])]{}

}

@subsection{Executions (otherwise known as trades)}

@defclass[executions-req% ibkr-msg% (req-msg<%>)]{

Request message to receive @racket[execution-rsp]s. As an example,

@racketblock[
(send ibkr send-msg (new executions-req%))
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
		 [soft-dollar-tier-value string? ""])]{

Please note that the fields @racket[action], @racket[order-type], @racket[time-in-force], @racket[open-close], and @racket[origin]
 use defaults that are not the @racket[#f], @racket[0], or @racket[""] typical defaults. Also note that you need to manage
 @racket[order-id] on your own. If you do not supply an @racket[order-id], it will use 0 and you will likely get an error stating
 the order ID has already been used.

}}

@section{Response messages}

@defmodule[interactive-brokers-api/response-messages]

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
     (ev-multiplier string?))]{

When receiving contract details, it is often nice to use the @racket[contract-id] for subsequent new order or market data
requests as these identifiers are unique.

}

@defstruct[err-rsp
    ((id integer?)
     (error-code integer?)
     (error-msg string?))]{

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
     (model-code string?))]{

It is recommended to periodically call @racket[executions-req%] to make sure you receive all of the executions that have occurred.

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
     (algo-strategy-params (listof string?))
     (solicited boolean?)
     (what-if boolean?)
     (status string?)
     (initial-margin (or/c rational? #f))
     (maintenance-margin (or/c rational? #f))
     (equity-with-loan (or/c rational? #f))
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
     (soft-dollar-tier-display-name string?))]{

This response is largely just telling you what you already provided to @racket[place-order-req%]. The fields of interest here
 are the generated @racket[client-id] and @racket[perm-id].

}

@section{Base Structs}

@defmodule[interactive-brokers-api/base-structs]

These structs are used for placing complex orders. You must @racket[require] the module to use them.

@defstruct[combo-leg
    ((contract-id integer?)
     (ratio integer?)
     (action (or/c 'buy 'sell 'sshort))
     (exchange string?)
     (open-close (or/c 'same 'open 'close #f))
     (short-sale-slot (or/c 0 1 2))
     (designated-location string?)
     (exempt-code integer?))]{

Use @racket[combo-leg] when you want to place a spread. This is commonly done for options and will work for many strategies. Note
 that you can only provide @racket[contract-id], which you can retrieve from @racket[contract-details-req%].

}

@defstruct[condition
((type (or/c 'price 'time 'margin
             'execution 'volume 'percent-change))
     (boolean-operator (or/c 'and 'or))
     (comparator (or/c 'less-than 'greater-than))
     (value (or/c rational? moment?))
     (contract-id (or/c integer? #f))
     (exchange (or/c string? #f))
     (trigger-method (or/c 'default 'double-bid/ask 'last
                           'double-last 'bid/ask 'last-of-bid/ask
			   'mid-point #f)))]{

Use @racket[condition] when you want your order to either take effect or be canceled only when certain conditions are met. Currently,
 only @racket['price] and @racket['time] do anything useful within the client.

}
