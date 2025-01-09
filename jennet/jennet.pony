use "collections"
use "files"
use "http_server"
use "net"
use "valbytes"

class iso Jennet
  let _out: OutStream
  let _auth: TCPListenAuth val
  var _responder: Responder
  var _base_middlewares: Array[Middleware] val = []
  let _routes: Array[_Route] iso = recover Array[_Route] end
  var _notfound: _HandlerGroup = _HandlerGroup(_DefaultNotFound)
  var _host: String = "Jennet" // TODO get host from server

  new iso create(
    auth: TCPListenAuth val,
    out: OutStream,
    responder: (Responder | None) = None)
  =>
    _responder =
      match responder
      | let r: Responder => r
      else DefaultResponder(out)
      end
    _out = out
    _auth = auth

  fun ref get(
    path: String,
    handler: RequestHandler,
    middlewares: Array[Middleware] val = [])
  =>
    """
    Create a route for a GET method on the given URL path with the given
    handler and middleware.
    """
    _add_route("GET", path, handler, middlewares)

  fun ref post(
    path: String,
    handler: RequestHandler,
    middlewares: Array[Middleware] val = [])
  =>
    """
    Create a route for a POST method on the given URL path with the given
    handler and middleware.
    """
    _add_route("POST", path, handler, middlewares)

  fun ref put(
    path: String,
    handler: RequestHandler,
    middlewares: Array[Middleware] val = [])
  =>
    """
    Create a route for a PUT method on the given URL path with the given
    handler and middleware.
    """
    _add_route("PUT", path, handler, middlewares)

  fun ref patch(
    path: String,
    handler: RequestHandler,
    middlewares: Array[Middleware] val = [])
  =>
    """
    Create a route for a PATCH method on the given URL path with the given
    handler and middleware.
    """
    _add_route("PATCH", path, handler, middlewares)

  fun ref delete(
    path: String,
    handler: RequestHandler,
    middlewares: Array[Middleware] val = [])
  =>
    """
    Create a route for a DELETE method on the given URL path with the given
    handler and middleware.
    """
    _add_route("DELETE", path, handler, middlewares)

  fun ref options(
    path: String,
    handler: RequestHandler,
    middlewares: Array[Middleware] val = [])
  =>
    """
    Create a route for an OPTIONS method on the given URL path with the given
    handler and middleware.
    """
    _add_route("OPTIONS", path, handler, middlewares)

  fun ref serve_file(auth: FileAuth, path: String, filepath: String) =>
    """
    Serve static file located at the relative filepath when GET requests are
    received for the given path.
    """
    let caps = recover val FileCaps + FileRead + FileStat + FileSeek end
    _add_route("GET", path, _FileServer(FilePath(auth, filepath, caps)), [])

  fun ref serve_dir(auth: FileAuth, path: String, dir: String) =>
    """
    Serve all files in dir using the incomming url path suffix denoted by
    `*filepath` in the given path.
    """
    let caps = recover val FileCaps + FileRead + FileStat + FileLookup + FileSeek end
    _add_route("GET", path, _DirServer(FilePath(auth, dir, caps)), [])

  fun ref not_found(handler: RequestHandler) =>
    """
    Replace the default RequestHandler for NotFound responses.
    """
    _notfound = _HandlerGroup(handler)

  fun ref base_middleware(mw: Array[Middleware] val) =>
    """
    Replace the middleware added to all routes.
    """
    _base_middlewares = mw

  fun val serve(config: ServerConfig, dump_routes: Bool = false): (Server | None) =>
    """
    Serve incomming HTTP requests. Return the Server, or None if routes are invalid.
    """
    let mux = try _Mux(_routes)? else return None end
    if dump_routes then _out.print(mux.debug()) end
    let router_factory = _RouterFactory(consume mux, _responder, _notfound)
    Server(_auth, _ServerInfo(_out, _responder), router_factory, config)

  fun ref _add_route(method: String, path: String,
    handler: RequestHandler, middlewares: Array[Middleware] val)
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

class val _RouterFactory is HandlerFactory
  let _mux: _Mux
  let _responder: Responder
  let _not_found: _HandlerGroup

  new val create(mux: _Mux, responder: Responder, not_found: _HandlerGroup) =>
    _mux = mux
    _responder = responder
    _not_found = not_found

  fun apply(session: Session): Handler ref^ =>
    recover ref _Router(_mux, _responder, _not_found, session) end

interface val Middleware
  fun val apply(ctx: Context): Context iso^ ?
  fun val after(ctx: Context): Context iso^ => consume ctx

interface val RequestHandler
  fun val apply(ctx: Context): Context iso^ ?

class _DefaultNotFound is RequestHandler
  fun val apply(ctx: Context): Context iso^ =>
    ctx.respond(
      StatusResponse(StatusNotFound),
      StatusNotFound.string().array())
    consume ctx

primitive StatusResponse
  fun apply(
    status: Status,
    headers: Array[(String, String)] box = [],
    close: Bool = true)
    : BuildableResponse iso^
  =>
    let res = recover BuildableResponse(status) end
    for (k, v) in headers.values() do
      res.add_header(k, v)
    end
    if close and (res.header("Connection") is None) then
      res.add_header("Connection", "close")
    end
    res
