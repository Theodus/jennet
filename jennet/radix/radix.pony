use "collections"
use "itertools"

// TODO: radix tree, param/wild matching

class Radix[A: Any val] // TODO: Any #share?
  embed _temporary_table: Map[String, A] = Map[String, A]

  fun ref update(path: String, value: A) =>
    _temporary_table(path) = value

  fun apply(path: String): (A | None) =>
    try _temporary_table(path)? end

  fun dbg(): String =>
    "\n".join(Iter[(String, A)](_temporary_table.pairs())
      .map[String](
        {(tup) =>
          " ".join(
            [ tup._1; ":"
              // iftype A <: Stringable val then tup._2.string() else "??" end
              match tup._2 | let s: Stringable val => s.string() else "??" end
            ].values())
        }))
