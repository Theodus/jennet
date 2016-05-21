use "collections"
use "net/http"

// TODO Radix Mux

class val _Multiplexer
  let _routes: Map[String, _HandlerGroup]
  let _not_found: _HandlerGroup

  new val create(routes: Array[_Route] iso, notfound: Handler) =>
    _routes = Map[String, _HandlerGroup](routes.size())
    for r in (consume routes).values() do
      _routes(r.path) = _HandlerGroup(r.middlewares, r.handler)
    end
    _not_found = _HandlerGroup(recover Array[Middleware] end, notfound)

  fun val apply(req: Payload) =>
    let hg = try
      _routes(req.url.string())
    else
      _not_found
    end
    let params = recover Map[String, String]() end
    let data = recover Map[String, Any]() end
    try hg(Context(consume params, consume data), consume req) end
