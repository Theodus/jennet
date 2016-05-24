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
// TODO mux tests
// TODO docs (readme explanation)

class _Multiplexer1 // TODO replace other mux
  let _trees: Map[String, _Tree]

  fun add(route: _Route) ? =>
    let path = route.path
    if path(path.size() - 1) != '/' then
      path.append("/")
    end
    let method = route.method
    let hg = _HandlerGroup(route.middlewares, route.handler)
    if _trees.contains(method) then
      let chunks = chunk(path)
      _trees(method).add(chunks, hg)
    else
      _trees(method) = _Tree(chunks, hg)
    end

  fun apply(req: Payload) ? =>
    let tree = _trees(req.method)
    let chunks = chunk(req.url.path)
    tree(chunks)

  fun chunk(path: String): Array[_Chunk] ? =>
    let ss = path.split("/")
    let cs = Array[_Chunk](ss.size())
    for (i, s) in ss.pairs() do
      if i == (ss.size() - 1) then
        match s
        | "" => cs.push(_Edge)
        else // TODO correct // ?
          if s(0) == '*' then
            cs.push(_Wild(s.substring(1)))
          end
        end
      else
        match s(0)
        | ':' =>
          cs.push(_Param(s.substring(1)))
        else
          cs.push(s)
        end
      end
    end
    cs

type _Chunk is (String | _Param | _Wild | _Edge)

class val _Param
  let name: String

  new val create(name': String) =>
    name = name'

class val _Wild
  let name: String

  new val create(name': String) =>
    name = name'

primitive _Edge

class _Tree
  let prefix: Array[_Chunk]
  let children: Array[_Tree]
  let leaf: (_Wild | _Edge | None)

  new create(chunks: Array[_Chunk], hg: _HandleGroup) =>

