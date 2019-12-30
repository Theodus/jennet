use "collections"
use "itertools"

use "debug" // TODO: remove

// TODO: radix tree, param/wild matching

type Result[A: Any val] is ((A | None), String)

class Radix[A: Any val] // TODO: Any #share?
  embed _root: Node[A] = Node[A]

  fun ref update(path: String, value: A) ? =>
    if path.contains("*") then
      let wild_before_end =
        try path.find("*")?.usize() != (path.size() - 1) else false end
      if wild_before_end or (path.size() < 2) then error end
    end
    _root.add(path, value)

  fun apply(path: String): Result[A] =>
    _root(path)

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
        prefix.append(prefix'.substring(0, -1))
        Debug(["  set wild"; prefix], " ")
        add(prefix', terminal')
      else
        Debug(["  set"; prefix'], " ")
        prefix.append(prefix')
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
      Debug(["  wild child"], " ")
      let c = recover ref Node[A, Wild] end
      for c' in children'.values() do c.children.push(c') end
      c.wild = wild'
      c.terminal = terminal'
      if prefix' == "*" then
        wild = consume c
      else
        let c' = recover ref Node[A] end
        c'.prefix.append(prefix'.substring(0, -1))
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

  fun apply(path: String): Result[A] =>
    let len = common_prefix(path)
    Debug(["apply"; prefix; path; len], " ")

    iftype N <: Wild then
      Debug(["  wild"], " ")
      (terminal, path)
    else
      if path == prefix then return (terminal, "") end

      for c in children.values() do
        let path' = path.trim(len)
        let len' = c.common_prefix(path') // TODO: pass down len'
        Debug(["  check"; c.prefix; path'], " ")
        if c.prefix.size() <= len' then
          Debug(["  child"; path'], " ")
          return c(path')
        end
      end
      match wild
      | let c: Node[A, Wild] box => return c(path.trim(len))
      end
      (None, "")
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

type RadixNode is (Normal | Wild)
primitive Normal
primitive Wild
