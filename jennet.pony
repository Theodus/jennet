// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "net/http"
use "net"
use "collections"

// TODO docs
// TODO ambient auth required?

class iso Jennet
  let _server: Server
  let _out: OutStream
  let _auth: (AmbientAuth val | NetAuth val)
  let _responder: Responder
  let _base_middlewares: Array[Middleware]
  let _routes: Array[_Route] iso = recover Array[_Route] end
  let _notfound: _HandlerGroup = _HandlerGroup(_DefaultNotFound)
  var _host: String = "Jennet" // TODO get host from server

  new iso create(
    auth: (AmbientAuth val | NetAuth val), out: OutStream, service: String)
  =>
    _server = Server(auth, _ServerInfo(out), _Unavailable, DiscardLog
      where service = service, reversedns = auth)
    _out = out
    _auth = auth
    _responder = DefaultResponder(out)
    _base_middlewares = Array[Middleware](1)
    _base_middlewares.push(ResponseTimer)

  // TODO custom default middleware
  // TODO other methods
  // TODO custom not_found

  fun ref get(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    _add_route("GET", path, handler, middlewares)

  fun ref serve_file(auth: AmbientAuth, path: String, filepath: String) =>
    _add_route("GET", path, _FileServer(auth, filepath),
    recover Array[Middleware] end)

  fun val serve() ? =>
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

type Middlewares is Array[Middleware] val

class _DefaultNotFound is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    c.respond(consume req, _NotFoundRes())
    consume c

primitive _NotFoundRes
  fun apply(): Payload iso^ =>
    let res = Payload.response(404, "Not Found")
    res.add_chunk("404: Not Found")
    consume res
