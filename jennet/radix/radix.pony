use "collections"
use "itertools"

use "debug" // TODO: remove

// TODO: param matching

class Radix[A: Any val] // TODO: Any #share?
  embed _root: Node[A] = Node[A]

  fun ref update(path: String, value: A) ? =>
    let no_wild_name =
      try path.find("*")?.usize() == (path.size() - 1) else false end
    let no_param_name =
      try path.find(":")?.usize() == (path.size() - 1) else false end
    if no_wild_name or no_param_name then error end

    _root.add(path, value)

  fun val apply(path: String, params: Map[String, String]): (A | None) =>
    _root(path, params)

  fun string(): String iso^ =>
    _root.debug()

class Node[A: Any val, N: RadixNode = Normal]
  embed prefix: String trn = recover String end
  embed children: Array[Node[A]] = []
  var wild: (Node[A, Wild] | None) = None
  var terminal: (A | None) = None

  fun ref add(prefix': String, terminal': (A | None))
  =>
    let len = common_prefix(prefix')
    Debug(["add"; prefix; prefix'; len], " ")

    if prefix == "" then
      // empty prefix, set prefix
      if prefix'.contains("*") then
        try prefix.append(prefix'.substring(0, prefix'.find("*")?)) end
        Debug(["  set wild"; prefix], " ")
        try _add_child(prefix'.substring(prefix'.find("*")?), terminal') end
      else
        prefix.append(prefix')
        Debug(["  set"; prefix], " ")
        terminal = terminal'
      end
    elseif prefix == prefix' then
      // equal prefix, replace terminal
      Debug(["  update"], " ")
      terminal = terminal'
    elseif len == prefix.size() then
      // prefix match, search children
      for c in children.values() do
        let p' = prefix'.trim(len)
        if c.common_prefix(p') > 0 then
          // add to child
          Debug(["  child"], " ")
          c.add(consume p', terminal')
          return
        end
      end
      // new child
      _add_child(prefix'.trim(len), terminal')
    else
      _add_child(
        prefix.substring(len.isize()),
        terminal = terminal',
        children,
        wild = None)

      children.remove(0, children.size() - 1)
      prefix.trim_in_place(0, len)
      Debug(["  set"; prefix], " ")

      if len != prefix'.size() then
        // prefix' is not substring, split prefix
        _add_child(prefix'.trim(len), terminal')
      end
    end

  fun ref _add_child(
    prefix': String,
    terminal': (A | None),
    children': Array[Node[A]] = [],
    wild': (Node[A, Wild] | None) = None)
  =>
    if prefix'.contains("*") then
      let c = recover ref Node[A, Wild] end
      try c.prefix.append(prefix'.substring(prefix'.find("*")? + 1)) end
      Debug(["  wild child"; c.prefix], " ")
      for c' in children'.values() do c.children.push(c') end
      c.wild = wild'
      c.terminal = terminal'
      if (try prefix'(0)? == '*' else false end) then
        wild = consume c
      else
        let c' = recover ref Node[A] end
        try c'.prefix.append(prefix'.substring(0, prefix'.find("*")?)) end
        c'.wild = consume c
        children.push(consume c')
      end
    else
      Debug(["  child"; prefix'], " ")
      let c = recover ref Node[A] end
      c.terminal = terminal'
      c.prefix.append(prefix')
      for c' in children'.values() do c.children.push(c') end
      c.wild = wild'
      children.push(consume c)
    end

  fun val apply(path: String, params: Map[String, String]): (A | None) =>
    let len = common_prefix(path)
    Debug(["apply"; prefix; path; len], " ")

    iftype N <: Wild then
      Debug(["  wild"; prefix], " ")
      params(prefix) = path
      terminal
    else
      if path == prefix then return terminal end

      for c in children.values() do
        let path' = path.trim(len)
        let len' = c.common_prefix(path') // TODO: pass down len'
        Debug(["  check"; c.prefix; path'], " ")
        if c.prefix.size() <= len' then
          Debug(["  child"; path'], " ")
          return c(path', consume params)
        end
      end
      match wild
      | let c: Node[A, Wild] val => return c(path.trim(len), consume params)
      end
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

  fun debug(indent_level: USize = 0): String iso^ =>
    "  ".join(Array[String].init("", indent_level + 1).values())
      .> append("'") .> append(prefix) .> append("'")
      .> append(iftype N <: Wild then " *" else "" end)
      .> append(" ") .> append(if terminal is None then "" else "$" end)
      .> append(if children.size() > 0 then "\n" else "" end)
      .> append("\n".join(Iter[Node[A] box](children.values())
          .map[String]({(n) => n.debug(indent_level + 1) })))
      .> append(
          try "\n" + (wild as Node[A, Wild] box).debug(indent_level + 1)
          else ""
          end)

type RadixNode is (Normal | Param | Wild)
primitive Normal
primitive Param
primitive Wild
