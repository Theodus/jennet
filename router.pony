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
  var _mux: (_Multiplexer | None) = None // TODO _RadixMux
  let _routes: Array[Route] = Array[Route]
  let _base_middleware: (Array[Middleware] | None)

  new iso create() =>
    _mux = None
    _base_middleware = None

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

  fun ref get(path: String, handler: Handler): Route =>
    let route = Route._create("GET", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref post(path: String, handler: Handler): Route =>
    let route = Route._create("POST", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref put(path: String, handler: Handler): Route =>
    let route = Route._create("PUT", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref delete(path: String, handler: Handler): Route =>
    let route = Route._create("DELETE", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref patch(path: String, handler: Handler): Route =>
    let route = Route._create("PATCH", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref head(path: String, handler: Handler): Route =>
    let route = Route._create("HEAD", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref options(path: String, handler: Handler): Route =>
    let route = Route._create("OPTIONS", path, handler, _base_middleware)
    _routes.push(route)
    route

  fun ref start() =>
    _mux = _Multiplexer(_routes)

class _Multiplexer
  let _routes: Map[String, _HandlerGroup]

  new create(routes: Array[Route]) =>
    _routes = Map[String, _HandlerGroup](routes.size())
    for r in routes.values() do
      _routes(r.path()) = _HandlerGroup(r.middleware(), r.handler())
    end

  fun apply(request: Payload) ? =>
    let hg = _routes(request.url.string())
    let params = recover Map[String, String]() end
    let data = recover Map[String, Any]() end
    hg(Context(consume request, consume params, consume data))
