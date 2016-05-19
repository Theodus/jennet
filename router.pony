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
  let _notify: _RouterNotify
  let _server: http.Server
  var _debug: Bool

  new create(auth: TCPListenerAuth, logger: Logger, host: String = "",
    service: String = "0", limit: USize = 0, sslctx: (SSLContext | None) = None,
    reversedns: (DNSLookupAuth | None) = None)
  =>
    // TODO docs
    _notify = _RouterNotify(logger)
    _server = http.Server(auth, _notify, this, logger, host, service, limit,
      sslctx, reversedns)
    _debug = debug

  fun val apply(request: http.Payload) =>
    // TODO docs
    None // TODO
