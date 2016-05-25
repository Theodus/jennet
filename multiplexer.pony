use "collections"
use "net/http"

class val _BadMultiplexer
  let _routes: Map[String, _HandlerGroup]
  let _notfound: _HandlerGroup
  let _responder: Responder

  new val create(routes: Array[_Route] iso, notfound: Handler,
    responder: Responder)
  =>
    _routes = Map[String, _HandlerGroup](routes.size())
    for r in (consume routes).values() do
      _routes(r.path) = _HandlerGroup(r.middlewares, r.handler)
    end
    _notfound = _HandlerGroup(recover Array[Middleware] end, notfound)
    _responder = responder

  fun val apply(req: Payload) =>
    let hg = try
      _routes(req.url.string())
    else
      _notfound
    end
    let params = recover Map[String, String]() end
    try
      hg(Context(_responder, consume params), consume req)
    end

// TODO Radix Mux
// TODO mux tests
// TODO docs (readme explanation)

type _Param is (String, String)

class _Node
  let path: String
  let methods: Map[String, _HandlerGroup] = Map[String, _HandlerGroup]
  let indices: String = ""
  let children: Array[_Node] = Array[_Node]
  let max_params: USize = 0

  new create(path': String) =>
    path = path'

  fun find(src: String, target: U8, start: USize, n: USize): USize ? =>
    var i = start
    while (i < n) and (src(i) != target) do
      i = i + 1
    end
    i

  fun ref add_methods(methods': Array[String], hg: _HandlerGroup) ? =>
    for m in methods'.values() do
      if methods.contains(m) then error end
      methods(m) = hg
    end

  fun get_index_pos(target: U8): USize ? =>
    var low = USize(0)
    var high = indices.size()
    while low < high do
      let mid = low + ((high - low) >> 1)
      if indices(mid) < target then
        low = mid + 1
      else
        high = mid
      end
    end
    low
