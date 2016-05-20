use "net"
use "net/ssl"
use "net/http"
use "collections"

/* TODO
 - dirty routes (route correction)
 - method not allowed handler
 - internal server error
 - serve_file
 - serve_dir
 - docs

Middleware:
 - logging (colorful)
*/

class iso Router
  var _mux: (_Multiplexer | None) = None
  let _routes: Array[_Route] = Array[_Route]
  let _base_middleware: Array[Middleware]

  new iso create() =>
    _mux = None
    _base_middleware = Array[Middleware]

  //TODO default

  fun val apply(request: Payload) =>
    // TODO spin up actor
    match _mux
    | let mux: _Multiplexer val =>
      try
        mux(consume request)
      else
        // TODO 505
        None
      end
    else
      // TODO 404
      None
    end

  fun ref get(path: String, handler: Handler) =>
    let route = _Route("GET", path, handler, _base_middleware)
    _routes.push(route)

  fun ref start() =>
    _mux = _Multiplexer(_routes)
