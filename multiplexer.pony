use "collections"
use "net/http"

// TODO Radix Mux

class val _Multiplexer
  let _routes: Map[String, _HandlerGroup]
  let _notfound: _HandlerGroup
  let _responselogger: ResponseLogger

  new val create(routes: Array[_Route] iso, notfound: Handler,
    responselogger: ResponseLogger)
  =>
    _routes = Map[String, _HandlerGroup](routes.size())
    for r in (consume routes).values() do
      _routes(r.path) = _HandlerGroup(r.middlewares, r.handler)
    end
    _notfound = _HandlerGroup(recover Array[Middleware] end, notfound)
    _responselogger = responselogger

  fun val apply(req: Payload) =>
    let hg = try
      _routes(req.url.string())
    else
      _notfound
    end
    let params = recover Map[String, String]() end
    let data = recover Map[String, Any]() end
    try
      hg(Context(consume params, consume data, _responselogger), consume req)
    end
