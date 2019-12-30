use "collections"
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestRadix)
    test(Property1UnitTest[Array[String]](_TestRadix))

type G is Generators

class _TestRadix is (UnitTest & Property1[Array[String]])
  fun name(): String =>
    "Radix tree"

  fun apply(h: TestHelper) ? =>
    for path in ["/"; "/abc"; "/abc/"; "/def"].values() do
      let radix: Radix[USize] ref = Radix[USize]
      let check_path =
        {(path: String, v: USize) ? =>
          if (radix(path) as USize) != v then error end
        }
      radix("/abc") = 0
      radix(path) = 1
      h.log(radix.string())
      check_path("/abc", if path == "/abc" then 1 else 0 end)?
      check_path(path, 1)?
    end

  fun gen(): Generator[Array[String]] =>
    G.array_of[String](_TestGen.url() where max = 100)

  fun property(a: Array[String], h: PropertyHelper) =>
    let table = Map[String, USize]
    let radix = Radix[USize]

    for (i, url) in a.pairs() do
      h.log(url + " -> " + i.string())
      table(url) = i
      radix(url) = i
      h.log(radix.string())
    end

    for (k, v) in table.pairs() do
      match radix(k)
      | let n: USize => h.assert_eq[USize](v, n)
      | None => h.fail("not found: " + k)
      end
    end

primitive _TestGen
  fun url(): Generator[String] =>
    G.array_of[String](G.ascii_numeric(1, 5) where max = 5)
      .map[String]({(strs) => "/" + "/".join(strs.values())})
