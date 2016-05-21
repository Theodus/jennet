use "net/http"

// TODO docs

class iso RouteBuilder
  let _routes: Array[_Route] iso = recover Array[_Route] end
  let _base_middlewares: Array[Middleware]
  var _not_found: Handler = _DefaultNotFound

  new iso create() =>
    _base_middlewares = Array[Middleware]

  //TODO default

  fun ref get(path: String, handler: Handler,
    middlewares: Array[Middleware] val = recover Array[Middleware] end)
  =>
    let bms = _base_middlewares.size()
    let ms = recover
      Array[Middleware](bms + middlewares.size())
    end
    for m in _base_middlewares.values() do ms.push(m) end
    for m in middlewares.values() do ms.push(m) end
    let route = _Route("GET", path, handler, consume ms)
    _routes.push(route)

  // TODO other methods

  fun iso build(): Router =>
    let nf = _not_found
    let mux = _Multiplexer((consume this)._routes, nf)
    Router(mux)

class _DefaultNotFound is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response(404, "Not Found")
    res.add_chunk("404: Not Found")
    (consume req).respond(consume res)
    consume c
