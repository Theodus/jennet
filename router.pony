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
  let _base_middlewares: Array[Middleware]

  new iso create() =>
    _mux = None
    _base_middlewares = Array[Middleware]

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

  fun ref get(path: String, handler: Handler,
    middlewares: Middlewares = Middlewares(None))
  =>
    let bms = _base_middlewares.size()
    let ms = recover
      Array[Middleware](bms + middlewares.ms.size())
    end
    for m in _base_middlewares.values() do ms.push(m) end
    for m in middlewares.ms.values() do ms.push(m) end
    let route = _Route("GET", path, handler, Middlewares(consume ms))
    _routes.push(route)

  // TODO other methods

  fun ref start() =>
    _mux = _Multiplexer(_routes)


interface val Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^)
  fun val after(c: Context): Context iso^


interface val Handler
  fun val apply(c: Context, req: Payload): Context iso^


class val Middlewares
  let ms: Array[Middleware]

  new val create(middlewares: (Array[Middleware] iso | None)) =>
    ms = match consume middlewares
    | let ms': Array[Middleware] iso => consume ms'
    else
      recover Array[Middleware] end
    end
