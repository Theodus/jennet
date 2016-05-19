use "net"
use "net/ssl"
use "net/http"
use "collections"

/* TODO
 - dirty routes (route correction)
 - method not allowed handler
 - not found handler !!!
 - internal server error
 - serve_file
 - serve_dir
 - docs

Middleware:
 - logging (colorful)
*/

class Router
  let _mux: (_Multiplexer | None) = None // TODO _RadixMux
  let _ready: Bool = false
  let _routes: Array[Route] = Array[Route]
  let _base_middleware: (Array[Middleware] | None)

  new val create() =>
    _mux = _Multiplexer
    _base_middleware = None

  //TODO default

  fun val apply(request: Payload) =>
    // TODO spin up actor
    if _ready then
      None
    else
      None
    end

  fun ref get(path: String, handler: Handler): Route =>
    let route = Route("GET", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref post(path: String, handler: Handler): Route =>
    let route = Route("POST", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref put(path: String, handler: Handler): Route =>
    let route = Route("PUT", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref delete(path: String, handler: Handler): Route =>
    let route = Route("DELETE", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref patch(path: String, handler: Handler): Route =>
    let route = Route("PATCH", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref head(path: String, handler: Handler): Route =>
    let route = Route("HEAD", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref options(path: String, handler: Handler): Route =>
    let route = Route("OPTIONS", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref run() =>
    _mux = _Multiplexer(_routes)
    _ready = true

class _Multiplexer
  let _routes: Map[String, _HandlerGroup]

  new create(hg: Map[String, _HandlerGroup]) =>
    _routes = hg

  fun apply(request: Payload iso) ? =>
    let hg = _routes(request.url.string())
    let params = recover Map[String, String]() end
    let data = recover Map[String, Any]() end
    hg(Context(consume request, consume params, consume data))

  fun ref addRoute(path: String, hg: _HandlerGroup) =>
    _routes(path) = hg
