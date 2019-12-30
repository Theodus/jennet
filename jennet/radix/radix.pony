use "collections"
use "itertools"

use "debug" // TODO: remove

// TODO: radix tree, param/wild matching

class Radix[A: Any val] // TODO: Any #share?
  embed _root: Node[A] = Node[A]

  fun ref update(path: String, value: A) =>
    _root.add(path, value)

  fun apply(path: String): (A | None) =>
    _root(path)

  fun string(): String iso^ =>
    _root.debug()

class Node[A: Any val]
  embed prefix: String trn = recover String end
  embed children: Array[Node[A]] = []
  var terminal: (A | None) = None

  fun ref add(prefix': String, terminal': (A | None))
  =>
    let len = common_prefix(prefix')
    Debug(["add"; prefix; prefix'; len], " ")

    if prefix == "" then
      // empty prefix, set prefix
      Debug(["  set"; prefix'], " ")
      prefix.append(prefix')
      terminal = terminal'
    elseif prefix == prefix' then
      // equal prefix, replace terminal
      Debug(["  update"], " ")
      terminal = terminal'
    elseif len >= prefix.size() then
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
      let c: Node[A] ref = Node[A]
      c.prefix.append(prefix'.trim(len))
      c.terminal = terminal'
      Debug(["  new"; c.prefix], " ")
      children.push(consume c)
    elseif len == prefix'.size() then
      // prefix' is substring, break prefix
      let c: Node[A] ref = Node[A]
      c.prefix.append(prefix.substring(len.isize()))
      c.terminal = terminal = terminal'
      for c' in children.values() do c.children.push(c') end
      children.clear()
      Debug(["  break"; c.prefix], " ")
      children.push(consume c)
      prefix.trim_in_place(0, len)
      Debug(["  set"; prefix], " ")
    else
      // split prefix
      let c1: Node[A] ref = Node[A]
      c1.prefix.append(prefix.substring(len.isize()))
      c1.terminal = terminal = None
      for c' in children.values() do c1.children.push(c') end
      children.clear()
      Debug(["  split"; c1.prefix], " ")
      children.push(consume c1)

      let c2: Node[A] ref = Node[A]
      c2.prefix.append(prefix'.trim(len))
      c2.terminal = terminal'
      Debug(["  split"; c2.prefix], " ")
      children.push(consume c2)

      prefix.trim_in_place(0, len)
      Debug(["  set"; prefix], " ")
    end

  fun apply(path: String, common_prefix': USize = 0): (A | None) =>
    let len = common_prefix(path)
    Debug(["apply"; prefix; path; len], " ")
    if path == prefix then return terminal end

    for c in children.values() do
      let path' = path.trim(len)
      let len' = c.common_prefix(path') // TODO: pass down len'
      Debug(["  check"; c.prefix; path'], " ")
      if len' > 0 then
        Debug(["  child"; path'], " ")
        return c(path')
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
      .> append(" ") .> append(if terminal is None then "" else "$" end)
      .> append(if children.size() > 0 then "\n" else "" end)
      .> append("\n".join(Iter[Node[A] box](children.values())
          .map[String]({(n) => n.debug(indent_level + 1) })))
