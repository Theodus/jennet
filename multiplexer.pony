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

class iso _Multiplexer1 // TODO replace other mux
  let _trees: Map[String, _Tree]

  new create() =>
    _trees = Map[String, _Tree]

  fun ref add(route: _Route) ? =>
    let path = route.path.clone()
    // remove first /
    if path(0) == '/' then path.shift() end
    // add last /
    if path(path.size() - 1) != '/' then path.append("/") end
    let method = route.method
    let hg = _HandlerGroup(route.middlewares, route.handler)
    let chunks = chunk(consume path)
    if _trees.contains(method) then
      _trees(method).add(chunks, hg)
    else
      _trees(method) = _Tree(chunks, hg)
    end

  fun apply(req: Payload): (_HandlerGroup, Map[String, String]) ? =>
    let tree = _trees(req.method)
    let p = req.url.path.clone()
    // remove first /
    if p(0) == '/' then p.shift() end
    // add last /
    if p(p.size() - 1) != '/' then p.append("/") end
    let path = recover ref p.split("/") end
    let params = Map[String, String]
    let hg = tree(path, params)
    (hg, params)

  fun chunk(path: String): Array[_Chunk] ? =>
    let ss = recover ref (consume path).split("/") end
    let cs = Array[_Chunk](ss.size())
    for (i, s) in ss.pairs() do
      if i == (ss.size() - 1) then
        match s
        | "" => cs.push(_Edge)
        else
          // TODO correct "//" ?
          if s(0) == '*' then
            cs.push(_Wild(s.substring(1)))
          else
            error
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

/* wightning children
    - param comes last
    - there may only be one param
    - the rest are ordered from greatest to least weight
*/ // TODO remove when done

class _Tree
  let prefix: Array[_Chunk]
  let wight: USize = 1
  let children: Array[_Tree]
  let leaf: (_Wild | _Edge | None)
  let hg: _HandlerGroup

  new create(chunks: Array[_Chunk], hg': _HandlerGroup) ? =>
    let last = chunks.size() - 1
    prefix = chunks.slice(0, last - 1)
    children = Array[_Tree]
    leaf = match chunks(last)
    | let w: _Wild => w
    | let e: _Edge => e
    else
      error
    end
    hg = hg'

  fun ref add(chunks: Array[_Chunk], hg': _HandlerGroup) ? =>
    // TODO
    error

  fun apply(path: Array[String], params: Map[String, String]):
    _HandlerGroup ?
  =>
    for (i, c) in prefix.pairs() do
      match c
      | let param: _Param =>
        params(param.name) = path(i)
      end
    end

    let path' = path.slice(prefix.size() - 1)
    let p = path'(0)
    if path'.size() == 1 then
      match leaf
      | let w: _Wild =>
        params(w.name) = p
        return hg
      | _Edge =>
        if p == "" then
          return hg
        else
          error
        end
      else
        error
      end
    else
      for c in children.values() do
        match c.prefix(0)
        | let s: String =>
          if p == s then
            c(path', params)
          end
        else
          c(path', params)
        end
      end
    end
    error
