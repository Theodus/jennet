// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "collections"
use "http"

// TODO weight optimization
// TODO path auto-correction

class iso _Multiplexer
  let _methods: Map[String, _Node]

  new iso create(routes: Array[_Route] val) ? =>
    _methods = Map[String, _Node]
    for r in routes.values() do
      let method = r.method
      let hg = _HandlerGroup(r.hg.handler, r.hg.middlewares)
      if _methods.contains(method) then
        _methods(method)?.add(r.path.clone(), hg)?
      else
        _methods(method) = _Node(r.path, hg)
      end
    end

  fun apply(method: String, path: String):
    (_HandlerGroup, Map[String, String] iso^) ? =>
    let path' = if path(0)? != '/' then
      let p = recover String(path.size() + 1) end
      p.append("/")
      p.append(consume path)
      consume p
    else
      consume path
    end
    let n = _methods(method)?
    n(consume path', recover Map[String, String] end)?

class _Node
  let prefix: String
  let _params: Map[USize, String]
  var _hg: (_HandlerGroup | None)
  let _children: Array[_Node]

  new create(
    prefix': String,
    hg': (_HandlerGroup | None) = None,
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
          if pfx(i)? == ':' then
            let ns = try
              pfx.find("/", i.isize())?
            else
              pfx.size().isize()
            end
            _params(i) = pfx.substring(i.isize() + 1, ns)
            pfx.delete(i.isize() + 1, ns.usize())
          elseif pfx(i)? == '*' then
            _params(i) = pfx.substring(i.isize() + 1)
            pfx.delete(i.isize() + 1, pfx.size())
          end
        end
      end
    end
    prefix = consume pfx

  fun ref add(path: String iso, hg: _HandlerGroup): _Node ? =>
    if path.size() < prefix.size() then
      let n1 = create(consume path, hg, _params)
      n1.add_child(this)
      return n1
    end
    for i in Range[USize](0, prefix.size()) do
      if prefix(i)? == ':' then
        let ns = try
          path.find("/", i.isize())?
        else
          path.size().isize()
        end
        let value = path.substring(i.isize(), ns)
        if value == "" then error end
        path.delete(i.isize(), ns.usize())
      elseif prefix(i)? == '*' then
        path.delete(i.isize(), path.size())
      elseif prefix(i)? != path(i)? then
        // branch in prefix
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
      if c.prefix(0)? == remaining(0)? then
        return c.add(consume remaining, hg)?
      end
    end
    // add child and reorder
    let c = create(consume remaining, hg)
    _children.push(c)
    reorder()?
    this

  fun ref add_child(child: _Node) =>
    _children.push(child)

  fun ref reorder() ? =>
    // check if there are more than one param children
    var ps: USize = 0
    for c in _children.values() do
      if c.prefix(0)? == ':' then
        ps = ps + 1
      end
    end
    if ps > 1 then error end
    // give param child last priority
    if ps != 0 then
      for (i, c) in _children.pairs() do
        if c.prefix(0)? == ':' then
          _children.delete(i)?
          _children.push(c)
          break
        end
      end
    end

  fun apply(path: String, params: Map[String, String] iso):
    (_HandlerGroup, Map[String, String] iso^) ?
  =>
    var path' = path
    for i in Range[ISize](0, prefix.size().isize()) do
      if prefix(i.usize())? == ':' then
        // store params
        let ns = try
          path'.find("/", i.isize())?
        else
          path'.size().isize()
        end
        let value = path'.substring(i, ns)
        if value == "" then error end
        params(_params(i.usize())?) = consume value
        path' = path'.cut(i.isize(), ns)
      elseif prefix(i.usize())? == '*' then
        params(_params(i.usize())?) = path'.substring(i)
        path' = path'.cut(i.isize(), path'.size().isize())
      elseif prefix(i.usize())? != path'(i.usize())? then
        // not found
        error
      end
    end

    let remaining = path'.substring(prefix.size().isize())
    // check for edge
    if remaining == "" then
      return (_hg as _HandlerGroup, consume params)
    end
    // pass on to child
    for c in _children.values() do
      match c.prefix(0)?
      | '*' => return c(consume remaining, consume params)?
      | ':' => return c(consume remaining, consume params)?
      | remaining(0)? => return c(consume remaining, consume params)?
      end
    end
    // not found
    error
