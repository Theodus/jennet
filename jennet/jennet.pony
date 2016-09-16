// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "net/http"
use "net"
use "collections"

class iso Jennet
  let _server: Server
  let _out: OutStream
  let _auth: (AmbientAuth val | NetAuth val)
  var _responder: Responder
  var _base_middlewares: Array[Middleware] val = recover Array[Middleware] end
  let _routes: Array[_Route] iso = recover Array[_Route] end
  var _notfound: _HandlerGroup = _HandlerGroup(_DefaultNotFound)
  var _host: String = "Jennet" // TODO get host from server

  new iso create(
    auth: (AmbientAuth val | NetAuth val), out: OutStream, service: String)
  =>
    _server = Server(auth, _ServerInfo(out), _Unavailable, DiscardLog
      where service = service, reversedns = auth)
    _out = out
    _auth = auth
    _responder = DefaultResponder(out)

  fun ref get(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    """
    Create a route for a GET method on the given URL path with the given handler
    and middleware.
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
    Create a route for a PUT method on the given URL path with the given handler
    and middleware.
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

  fun ref serve_file(auth: AmbientAuth, path: String, filepath: String) =>
    """
    Serve static file located at the relative filepath when GET requests are
    recieved for the given path.
    """
    _add_route("GET", path, _FileServer(auth, filepath),
      recover Array[Middleware] end)

  fun ref serve_dir(auth: AmbientAuth, path: String, dir: String) =>
    """
    Serve all files in dir using the incomming url path suffix denoted by
    *filepath in the given path. path must be in the form of:
    "/some_dir/*filepath".
    """
    _add_route("GET", path, _DirServer(auth, dir),
      recover Array[Middleware] end)

  fun ref not_found(handler: Handler) =>
    """
    Replace the default Handler for NotFound responses.
    """
    _notfound = _HandlerGroup(handler)

  fun ref responder(r: Responder) =>
    """
    Replace the responder used for responding to requests and logging the
    responses.
    """
    _responder = r

  fun ref base_middleware(mw: Array[Middleware] val) =>
    """
    Replace the middleware added to all routes.
    """
    _base_middlewares = mw

  fun val serve() ? =>
    """
    Serve incomming HTTP requests.
    """
    let mux = _Multiplexer(_routes)
    let router = _Router(consume mux, _responder, _notfound, _host)
    _server.set_handler(router)

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

interface val Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) ?
  fun val after(c: Context): Context iso^

interface val Handler
  fun val apply(c: Context, req: Payload): Context iso^ ?

class _DefaultNotFound is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    c.respond(consume req, _NotFoundRes())
    consume c

primitive _NotFoundRes
  fun apply(): Payload iso^ =>
    let res = Payload.response(StatusNotFound)
    res.add_chunk("404: Not Found")
    consume res
