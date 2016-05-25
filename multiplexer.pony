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

class iso _Multiplexer // TODO replace other mux
  let _trees: Map[String, _Tree]

  new create() =>
    _trees = Map[String, _Tree]

  fun ref add(route: _Route) ? =>
    let path = route.path.clone()
    // remove first /
    if path(0) == '/' then path.shift() end
    // add last /
    if path(path.size() - 1) != '/' then path.append("/") end
    path.append("#")
    let method = route.method
    let hg = _HandlerGroup(route.middlewares, route.handler)
    if _trees.contains(method) then
      _trees(method).add(path.split("/"), hg)
    else
      _trees(method) = _Tree(path.split("/"), hg)
    end

  fun apply(req: Payload): (_HandlerGroup, Map[String, String]) ? =>
    let tree = _trees(req.method)
    let path = req.url.path.clone()
    // remove first /
    if path(0) == '/' then path.shift() end
    // add last /
    if path(path.size() - 1) != '/' then path.append("/") end
    path.append("#")
    let params = Map[String, String]
    let hg = tree(path.split("/"), params)
    (hg, params)

class _Tree
  let prefix: Array[String]
  let hg: (_HandlerGroup | None)
  let children: Array[_Tree] = Array[_Tree]
  var weight: USize

  new create(prefix': Array[String], hg': (_HandlerGroup | None) = None) =>
    prefix = prefix'
    hg = hg'
    weight = if hg' is None then 0 else 1 end

  fun first_is_param(): Bool => try prefix(0)(0) == ':' else false end

  fun ref add_child(t: _Tree) =>
    children.push(t)
    weight = weight + 1

  fun ref reorder() ? =>
    var j: USize = 1
    while j < children.size() do
      let k = children(j)
      var i = j - 1
      while (i >= 0) and (children(i).weight > k.weight) do
        children(i + 1) = children(i)
        i = i - 1
      end
      children(i + 1) = k
      j = j + 1
    end
    // give param lowest priority
    for (i, c) in children.pairs() do
      if c.first_is_param() then
        children.delete(i)
        children.push(c)
        break
      end
    end

  fun apply(path: Array[String], params: Map[String, String]): _HandlerGroup ?
  =>
    for (i, pth) in path.pairs() do
      let pfx = prefix(i)
      match pfx(0)
      | ':' =>
        params(pfx.substring(1)) = pth
      | '*' =>
        params(pfx.substring(1)) = pth
      | '#' =>
        return hg as _HandlerGroup
      else
        if pfx != pth then error end
      end
    end
    let path' = path.slice(prefix.size() - 1)
    for c in children.values() do
      if (c.prefix(0) == path'(0)) or (c.first_is_param()) then
        return c(path', params)
      end
    end
    error

  fun ref add(path: Array[String], hg': _HandlerGroup) ? =>
    /*
    for (i, pfx) in prefix.pairs() do
      let pth = path(i)
      if pfx != pth then


    */
    error
