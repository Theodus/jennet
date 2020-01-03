use "collections"
use "itertools"

class Radix[A: Any val]
  embed _root: Node[A] = Node[A]

  fun ref update(path: String, value: A) ? =>
    var check_path = path
    while true do
      let param_start =
        if check_path.contains(":") then check_path.find(":")? + 1
        elseif check_path.contains("*") then check_path.find("*")? + 1
        else break
        end
      let param = _root.extract_name(check_path, param_start.usize())
      match param
      | "" | "/" | ":" | "*" => error
      end
      check_path = check_path.trim(param_start.usize() + param.size())
    end

    _root.add(path, value)

  fun val apply(path: String, params: Map[String, String]): (A | None) =>
    _root(path, params)

  fun string(): String iso^ =>
    _root.debug()

class Node[A: Any val, N: RadixNode = Normal]
  embed prefix: String trn = recover String end
  embed children: Array[Node[A]] = []
  var param: (Node[A, Param] | Node[A, Wild] | None) = None
  var terminal: (A | None) = None

  fun ref add(prefix': String, terminal': (A | None))
  =>
    let len = common_prefix(prefix')

    if prefix == "" then
      // empty prefix, set prefix
      if prefix'.contains("*") then
        try prefix.append(prefix'.substring(0, prefix'.find("*")?)) end
        try _add_child(prefix'.substring(prefix'.find("*")?), terminal') end
      else
        prefix.append(prefix')
        terminal = terminal'
      end
    elseif prefix == prefix' then
      // equal prefix, replace terminal
      terminal = terminal'
    elseif len == prefix.size() then
      // prefix match, search children
      for c in children.values() do
        let p' = prefix'.trim(len)
        if c.common_prefix(p') > 0 then
          // add to child
          c.add(consume p', terminal')
          return
        end
      end
      if (try prefix'(len)? == ':' else false end) then
        let rest = prefix'.trim(len + 1)
        match param
        | let p: Node[A, Param] => return p.add(rest, terminal')
        end
      end
      // new child
      _add_child(prefix'.trim(len), terminal')
    else
      _add_child(
        prefix.substring(len.isize()),
        terminal = terminal',
        children,
        param = None)

      children.remove(0, children.size() - 1)
      prefix.trim_in_place(0, len)

      if len != prefix'.size() then
        // prefix' is not substring, split prefix
        _add_child(prefix'.trim(len), terminal')
        terminal = None
      end
    end

  fun ref _add_child(
    prefix': String,
    terminal': (A | None),
    children': Array[Node[A]] = [],
    param': (Node[A, Param] | Node[A, Wild] | None) = None)
  =>
    if prefix'.contains(":") then
      let name_start = try prefix'.find(":")?.usize() + 1 else -1 end
      if name_start != 1 then
        let c = recover ref Node[A] end
        c.prefix.append(prefix'.trim(0, name_start - 1))
        c._add_child(prefix'.trim(name_start - 1), terminal')
        children.push(consume c)
      else
        let c = recover ref Node[A, Param] end
        c.prefix.append(extract_name(prefix', name_start))
        let rest = prefix'.trim(name_start.usize() + c.prefix.size())
        if rest == "" then
          c.terminal = terminal'
          for c' in children'.values() do c.children.push(c') end
          c.param = param'
        else
          c._add_child(rest, terminal', children', param')
        end
        param = consume c
      end
    elseif prefix'.contains("*") then
      let name_start = try prefix'.find("*")?.usize() + 1 else -1 end
      if name_start != 1 then
        let c = recover ref Node[A] end
        c.prefix.append(prefix'.trim(0, name_start - 1))
        c._add_child(prefix'.trim(name_start - 1), terminal')
        children.push(consume c)
      else
        let c = recover ref Node[A, Wild] end
        c.prefix.append(extract_name(prefix', name_start))
        c.terminal = terminal'
        param = consume c
      end
    else
      let c = recover ref Node[A] end
      c.prefix.append(prefix')
      c.terminal = terminal'
      for c' in children'.values() do c.children.push(c') end
      c.param = param'
      children.push(consume c)
    end

  fun val apply(path: String, params: Map[String, String]): (A | None) =>
    if path == "" then return end
    iftype N <: Param then
      let value = extract_name(path, 0)
      params(prefix) = value
      if value == path
      then terminal
      else search(path.trim(value.size()), params)
      end
    elseif N <: Wild then
      params(prefix) = path
      terminal
    else
      if path == prefix then return terminal end
      search(path, params)
    end

  fun val search(path: String, params: Map[String, String]): (A | None) =>
    let len = common_prefix(path)
    for c in children.values() do
      let path' = path.trim(len)
      let len' = c.common_prefix(path') // TODO: pass down len'
      if c.prefix.size() <= len' then
        return c(path', consume params)
      end
    end
    match param
    | let p: Node[A, Param] val => return p(path.trim(len), consume params)
    | let w: Node[A, Wild] val => return w(path.trim(len), consume params)
    end

  fun common_prefix(path: String box): USize =>
    var i: USize = 0
    try
      while i < prefix.size().min(path.size()) do
        if prefix(i)? != path(i)? then break end
        i = i + 1
      end
    end
    i

  fun tag extract_name(path: String, start: USize): String =>
    var i: USize = start + 1
    try
      while i < path.size() do
        match path(i)?
        | ':' | '*' | '/' => return path.trim(start, i)
        end
        i = i + 1
      end
    end
    path.trim(start)

  fun debug(indent_level: USize = 0): String iso^ =>
    "  ".join(Array[String].init("", indent_level + 1).values())
      .> append("'") .> append(prefix) .> append("'")
      .> append(iftype N <: Param then " :" else "" end)
      .> append(iftype N <: Wild then " *" else "" end)
      .> append(" ") .> append(if terminal is None then "" else "$" end)
      .> append(if children.size() > 0 then "\n" else "" end)
      .> append("\n".join(Iter[Node[A] box](children.values())
          .map[String]({(n) => n.debug(indent_level + 1) })))
      .> append(
          match param
          | let p: Node[A, Param] box => "\n" + p.debug(indent_level + 1)
          | let w: Node[A, Wild] box => "\n" + w.debug(indent_level + 1)
          | None => ""
          end)

type RadixNode is (Normal | Param | Wild)
primitive Normal
primitive Param
primitive Wild
