use "collections"
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(Property1UnitTest[Array[String]](_TestRadix))

type G is Generators

class _TestRadix is Property1[Array[String]]
  fun name(): String =>
    "Radix"

  fun gen(): Generator[Array[String]] =>
    let url_gen =
      G.array_of[String](
        G.ascii_letters(0, 5).union[String](G.ascii_numeric(0, 5))
        where max = 6)
        .map[String]({(strs) => "/" + "/".join(strs.values())})

    G.array_of[String](url_gen)

  fun property(a: Array[String], ph: PropertyHelper) =>
    let table = Map[String, USize]
    let radix = Radix[USize]

    for (i, url) in a.pairs() do
      table(url) = i
      radix(url) = i
      ph.env.out.print(url + " -> " + i.string())
    end

    for (k, v) in table.pairs() do
      match radix(k)
      | let n: USize => ph.assert_eq[USize](v, n)
      | None => ph.fail("not found: " + k + "\n" + radix.dbg())
      end
    end
