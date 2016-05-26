use "collections"
use "net/http"

// TODO mux tests
// TODO docs (readme explanation)

class iso _Multiplexer
  let _methods: Map[String, _Node]
  let _responder: Responder
  let _notfound: _HandlerGroup

  new iso create(routes: Array[_Route] iso, responder: Responder,
    notfound: _HandlerGroup) ?
  =>
    _responder = responder
    _notfound = notfound
    _methods = Map[String, _Node]
    for r in (consume routes).values() do
      let method = r.method
      let hg = _HandlerGroup(r.hg.handler, r.hg.middlewares)
      if _methods.contains(method) then
        _methods(method).add(r.path.clone(), hg)
      else
        _methods(method) = _Node(r.path, hg)
      end
    end

  fun val apply(req: Payload) =>
    (let gh, let c) = try
      let req_path = req.url.string()
      var path = if req_path(0) != '/' then
        let p = recover String(req_path.size() + 1) end
        p.append("/")
        p.append(consume req_path)
        consume p
      else
        consume req_path
      end

      let n = _methods(req.method)
      (let gh', let params) = n(consume path, recover Map[String, String] end)
      let c' = Context(_responder, consume params)
      (gh', consume c')
    else
      let c = Context(_responder, recover Map[String, String] end)
      (_notfound, consume c)
    end
    try
      gh(consume c, consume req)
    end

class _Node
  let prefix: String
  let _params: Map[USize, String]
  var _hg: (_HandlerGroup | None)
  let _children: Array[_Node]

  new create(prefix': String, hg': (_HandlerGroup | None) = None,
    params': Map[USize, String] = Map[USize, String],
    children': Array[_Node] = Array[_Node])
  =>
    _params = params'
    _hg = hg'
    _children = children'
    // store param names and remove them form prefix
    let pfx = recover prefix'.clone() end
    if params'.size() == 0 then
      for i in Range[USize](0, pfx.size()) do
        try
          if pfx(i) == ':' then
            let ns = pfx.find("/", i.isize())
            _params(i) = pfx.substring(i.isize() + 1, ns)
            pfx.delete(i.isize() + 1, ns.usize())
          end
        end
      end
    end
    prefix = consume pfx

  fun ref add(path: String iso, hg: _HandlerGroup): _Node ? =>
    // search for edge in prefix
    if path.size() < prefix.size() then
      let n1 = create(consume path, hg, _params)
      n1.add_child(this)
      return n1
    end
    // search for branch in prefix
    for i in Range[USize](0, prefix.size()) do
      if prefix(i) != path(i) then
        // seperate params
        let params0 = Map[USize, String]
        let params1 = Map[USize, String]
        for (k, v) in _params.pairs() do
          if k < i then
            params0(k) = v
          else
            params1(k) = v
          end
        end
        // branch
        let n1 = create(prefix.substring(0, i.isize()), None, params0)
        let n2 = create(prefix.substring(i.isize()), _hg, params1, _children)
        let n3 = create(path.substring(i.isize()), hg)
        n1.add_child(n2)
        n1.add_child(n3)
        return n1
      end
    end

    let remaining = path.substring(prefix.size().isize())
    // create edge
    if remaining == "" then
      if _hg is None then
        _hg = hg
        return this
      else
        error
      end
    end
    // pass on to child
    for c in _children.values() do
      if c.prefix(0) == remaining(0) then
        return c.add(consume remaining, hg)
      end
    end
    // add child and reorder
    _children.push(create(consume remaining, hg))
    reorder()
    this

  fun ref add_child(child: _Node) =>
    _children.push(child)

  fun ref reorder() ? =>
    // check if there are more than one param children
    var ps: USize = 0
    for c in _children.values() do
      if c.prefix(0) == ':' then
        ps = ps + 1
      end
    end
    if ps > 1 then error end
    // give param child last priority
    if ps != 0 then
      for (i, c) in _children.pairs() do
        if c.prefix(0) == ':' then
          _children.delete(i)
          _children.push(c)
          break
        end
      end
    end

    fun apply(path: String, params: Map[String, String] iso):
      (_HandlerGroup, Map[String, String] iso^) ?
    =>
      for i in Range[ISize](0, prefix.size().isize()) do
        if prefix(i.usize()) == ':' then
          // store params
          params(_params(i.usize())) = path.substring(i, path.find("/", i))
        elseif prefix(i.usize()) != path(i.usize()) then
          // not found
          error
        end
      end

      let remaining = path.substring(prefix.size().isize())
      // check for edge
      if remaining == "" then
        return (_hg as _HandlerGroup, consume params)
      end
      // pass on to child
      for c in _children.values() do
        match c.prefix(0)
        | ':' => return c(consume remaining, consume params)
        | remaining(0) => return c(consume remaining, consume params)
        end
      end
      // not found
      error
