use "collections"
use "net/http"

// TODO Radix Mux

class _Multiplexer
  let _routes: Map[String, _HandlerGroup]

  new create(routes: Array[_Route]) =>
    _routes = Map[String, _HandlerGroup](routes.size())
    for r in routes.values() do
      _routes(r.path) = _HandlerGroup(r.middlewares, r.handler)
    end

  fun apply(request: Payload) ? =>
    let hg = _routes(request.url.string())
    let params = recover Map[String, String]() end
    let data = recover Map[String, Any]() end
    hg(Context(consume params, consume data), consume request)
