use "net"
use "net/ssl"
use http = "net/http"

/* TODO
 - dirty routes (route correction)
 - method not allowed handler

Middleware:
 - logging (colorful)
*/

actor Router
  // TODO docs
  // let _mux: _RadixMux
  let _logger: Logger
  let _server: http.Server

  new create(auth: TCPListenerAuth, logger: Logger, host: String = "",
    service: String = "0", limit: USize = 0, sslctx: (SSLContext | None) = None,
    reversedns: (DNSLookupAuth | None) = None)
  =>
    // TODO docs
    _logger = logger
    _server = http.Server(auth, None, this, logger, host, service, limit,
      sslctx, reversedns)

  fun val apply(request: http.Payload) =>
    // TODO docs
    None // TODO
