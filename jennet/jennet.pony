use "collections"
use "files"
use "http"
use "net"

class iso Jennet
  let _server: HTTPServer
  let _out: OutStream
  let _auth: (AmbientAuth val | NetAuth val)
  var _responder: Responder
  var _base_middlewares: Array[Middleware] val = recover Array[Middleware] end
  let _routes: Array[_Route] iso = recover Array[_Route] end
  var _notfound: _HandlerGroup = _HandlerGroup(_DefaultNotFound)
  var _host: String = "Jennet" // TODO get host from server

  new iso create(
    auth: (AmbientAuth val | NetAuth val),
    out: OutStream,
    service: String,
    responder: (Responder | None) = None)
  =>
    _responder =
      match responder
      | let r: Responder => r
      else DefaultResponder(out)
      end
    _server = HTTPServer(
      auth,
      _ServerInfo(out, _responder),
      _UnavailableFactory,
      DiscardLog
      where service = service, reversedns = auth)
    _out = out
    _auth = auth

  fun ref get(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for a GET method on the given URL path with the given
    handler and middleware.
    """
    _add_route("GET", path, handler, middlewares)

  fun ref post(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for a POST method on the given URL path with the given
    handler and middleware.
    """
    _add_route("POST", path, handler, middlewares)

  fun ref put(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for a PUT method on the given URL path with the given
    handler and middleware.
    """
    _add_route("PUT", path, handler, middlewares)

  fun ref patch(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for a PATCH method on the given URL path with the given
    handler and middleware.
    """
    _add_route("PATCH", path, handler, middlewares)

  fun ref delete(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for a DELETE method on the given URL path with the given
    handler and middleware.
    """
    _add_route("DELETE", path, handler, middlewares)

  fun ref options(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for an OPTIONS method on the given URL path with the given
    handler and middleware.
    """
    _add_route("OPTIONS", path, handler, middlewares)

  fun ref serve_file(auth: AmbientAuth, path: String, filepath: String) ? =>
    """
    Serve static file located at the relative filepath when GET requests are
    received for the given path.
    """
    let caps = recover val FileCaps + FileRead + FileStat end
    _add_route("GET", path, _FileServer(FilePath(auth, filepath, caps)?), [])

  fun ref serve_dir(auth: AmbientAuth, path: String, dir: String) ? =>
    """
    Serve all files in dir using the incomming url path suffix denoted by
    `*filepath` in the given path.
    """
    let caps = recover val FileCaps + FileRead + FileStat + FileLookup end
    _add_route("GET", path, _DirServer(FilePath(auth, dir, caps)?), [])

  fun ref not_found(handler: Handler) =>
    """
    Replace the default Handler for NotFound responses.
    """
    _notfound = _HandlerGroup(handler)

  fun ref base_middleware(mw: Array[Middleware] val) =>
    """
    Replace the middleware added to all routes.
    """
    _base_middlewares = mw

  fun val serve(dump_routes: Bool = false) ? =>
    """
    Serve incomming HTTP requests.
    """
    let mux = _Mux(_routes)?
    if dump_routes then _out.print(mux.debug()) end
    let router_factory = _RouterFactory(consume mux, _responder, _notfound)
    _server.set_handler(router_factory)

  fun dispose() =>
    _server.dispose()

  fun ref _add_route(method: String, path: String,
    handler: Handler, middlewares: Array[Middleware] val)
  =>
    let bms = _base_middlewares.size()
    let ms = recover
      Array[Middleware](bms + middlewares.size())
    end
    for m in _base_middlewares.values() do ms.push(m) end
    for m in middlewares.values() do ms.push(m) end
    let hg = _HandlerGroup(handler, consume ms)
    let route = _Route(method, path, hg)
    _routes.push(route)

class val _RouterFactory
  let _mux: _Mux
  let _responder: Responder
  let _not_found: _HandlerGroup

  new val create(
    mux: _Mux,
    responder: Responder,
    not_found: _HandlerGroup) =>
    _mux = mux
    _responder = responder
    _not_found = not_found

  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    recover ref _Router(_mux, _responder, _not_found) end

interface val Middleware
  fun val apply(c: Context, req: Payload val): (Context iso^, Payload val) ?
  fun val after(c: Context): Context iso^

interface val Handler
  fun val apply(c: Context, req: Payload val): Context iso^ ?

class _DefaultNotFound is Handler
  fun val apply(c: Context, req: Payload val): Context iso^ =>
    c.respond(req, _NotFoundRes())
    consume c

primitive _NotFoundRes
  fun apply(): Payload iso^ =>
    let res = Payload.response(StatusNotFound)
    res.add_chunk("404: Not Found")
    consume res
