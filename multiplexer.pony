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

// TODO Radix Mux
// TODO docs

class _RadixMux
  let root: _Node

  new create() =>
    root = _Node("/")

  fun update(path: String, hg: _HandlerGroup) =>
    // TODO
    None

  fun ref apply(req: Payload): (_HandlerGroup, Map[String, String]) ? =>
    var path = recover iso req.url.path.clone() end
    let method = req.method
    let params = Map[String, String]
    let hg = root(consume path, method, params)
    (hg, params)

class _Node
  let prefix: String
  let _edge: (_Edge | None) = None
  let _children: Array[_Node] = Array[_Node]
  let _leaves: Array[_Leaf] = Array[_Leaf]
  let _wild: (_Wild | None) = None
  let _param: (_Param | None) = None

  new create(prefix': String) =>
    prefix = prefix'

  fun update(path: String iso, hg: _HandlerGroup) =>
    // TODO
    None

  fun ref apply(path: String iso, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    if path.substring(0, prefix.size().isize()) == prefix then
      path.delete(0, prefix.size())
    else
      error
    end

    // Short circuit for edge
    if (path.size() == 0) then
      match _edge
      | let e: _Edge => return e(consume path, method, params)
      else
        error
      end
    end

    let next = path(0)
    for c in _children.values() do
      if c.prefix(0) == next then
        return c(consume path, method, params)
      end
    end
    for l in _leaves.values() do
      if l.prefix(0) == next then
        return l(consume path, method, params)
      end
    end
    match _wild
    | let w: _Wild => return w(consume path, method, params)
    end
    match _param
    | let p: _Param => return p(consume path, method, params)
    end
    error

class _Param
  let _name: String
  let _edge: (_Edge | None) = None
  let _children: Array[_Node] = Array[_Node]
  let _leaves: Array[_Leaf] = Array[_Leaf]
  let _wild: (_Wild | None) = None
  let _param: (_Param | None) = None

  new create(name: String) =>
    _name = name

  fun update(path: String iso, hg: _HandlerGroup) =>
    // TODO
    None

  fun ref apply(path: String iso, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    let s = path.substring(0, path.find("/"))
    path.delete(0, s.size())
    params(_name) = consume s

    // Short circuit for edge
    if (path.size() == 0) then
      match _edge
      | let e: _Edge => return e(consume path, method, params)
      else
        error
      end
    end

    let next = path(0)
    for c in _children.values() do
      if c.prefix(0) == next then
        return c(consume path, method, params)
      end
    end
    for l in _leaves.values() do
      if l.prefix(0) == next then
        return l(consume path, method, params)
      end
    end
    match _wild
    | let w: _Wild => return w(consume path, method, params)
    end
    match _param
    | let p: _Param => return p(consume path, method, params)
    end
    error

class _Edge
  let _methods: Array[String]
  let _hg: _HandlerGroup

  new create(methods: Array[String], hg: _HandlerGroup) =>
    _methods = methods
    _hg = hg

  fun apply(path: String iso, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    if _methods.contains(method) then
      _hg
    else
      error
    end

class _Leaf
  let prefix: String
  let _methods: Array[String]
  let _hg: _HandlerGroup

  new create(prefix': String, methods': Array[String], hg': _HandlerGroup) =>
    prefix = prefix'
    _methods = methods'
    _hg = hg'

  fun apply(path: String iso, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    if _methods.contains(method) then
      _hg
    else
      error
    end

class _Wild
  let _name: String
  let _methods: Array[String]
  let _hg: _HandlerGroup

  new create(name: String, methods: Array[String], hg: _HandlerGroup) =>
    _name = name
    _methods = methods
    _hg = hg

  fun apply(path: String iso, method: String, params: Map[String, String]):
    _HandlerGroup ?
  =>
    if _methods.contains(method) then
      params(_name) = path.substring(1)
      _hg
    else
      error
    end
