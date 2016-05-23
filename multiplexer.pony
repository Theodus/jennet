use "collections"
use "net/http"

class val _Multiplexer
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

/*
// TODO Radix Mux
// TODO docs

trait _RMNode
  fun update(path: String, hg: _HandlerGroup)
  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?

trait _RMLeaf
  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?

class _Node is _RMNode
  let _preifx: String
  let _children: Array[_RMNode]
  let _leaves: Array[_RMLeaf]

  fun update(path: String, hg: _HandlerGroup) =>
    // TODO
    None

  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    // TODO
    None

class _Param is _RMNode
  let _name: String
  let _children: Array[_RMNode]

  fun update(path: String, hg: _HandlerGroup) =>
    // TODO
    None

  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    // TODO
    None

class _Edge is _RMLeaf
  let _hg: _HandlerGroup
  let _method: String

  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    if method == _method then
      _hg
    else
      error
    end

class _Leaf is _RMLeaf
  let _prefix: String
  let _method: String
  let _hg: _HandlerGroup

  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    if method == _method then
      _hg
    else
      error
    end

class _Wild is _RMLeaf
  let _name: String
  let _hg: _HandlerGroup

  fun apply(path: String, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    // TODO
    None
*/
