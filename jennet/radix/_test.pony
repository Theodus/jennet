use "collections"
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestRadix)
    test(Property1UnitTest[Array[String]](_TestRadix))
    test(Property1UnitTest[Array[String]](_TestWild))

class _TestRadix is (UnitTest & Property1[Array[String]])
  fun name(): String =>
    "radix/tree"

  fun apply(h: TestHelper) ? =>
    for path in ["/"; "/abc"; "/abc/"; "/def"].values() do
      let radix: Radix[USize] ref = Radix[USize]
      let check_path =
        {(path: String, v: USize) ? =>
          if (radix(path) as (USize, String))._1 != v then error end
        }
      radix("/abc")? = 0
      radix(path)? = 1
      h.log(radix.string())
      check_path("/abc", if path == "/abc" then 1 else 0 end)?
      check_path(path, 1)?
    end

  fun gen(): Generator[Array[String]] =>
    Generators.array_of[String](_TestGen.url() where max = 100)

  fun property(a: Array[String], h: PropertyHelper) ? =>
    let table = Map[String, USize]
    let radix = Radix[USize]

    for (i, url) in a.pairs() do
      table(url) = i
      radix(url)? = i
      h.log(radix.string())
    end

    for (k, v) in table.pairs() do
      match radix(k)
      | (let v': USize, _) => h.assert_eq[USize](v, v')
      | (None, _) => h.fail("not found: " + k)
      end
    end

class _TestWild is Property1[Array[String]]
  fun name(): String =>
    "radix/wild"

  fun gen(): Generator[Array[String]] =>
    Generators.array_of[String](_TestGen.url() where min = 2, max = 10)

  fun property(a: Array[String], h: PropertyHelper) ? =>
    let table = Map[String, USize]
    let radix = Radix[USize]
    let wild_match = a.pop()?
    let wild_url = a.pop()?

    for (i, url) in a.pairs() do
      radix(url)? = i
      table(url) = i
    end
    radix(wild_url + "*")? = a.size()
    h.log(radix.string())

    for (k, v) in table.pairs() do
      match radix(k)
      | (let v': USize, let w: String) =>
        h.assert_eq[USize](v', v)
        h.assert_eq[String](w, "")
      | (None, _) =>
        h.fail("not found: " + k)
      end
    end
    match radix(wild_url + wild_match)
    | (let v': USize, let w: String) =>
      h.assert_eq[USize](v', a.size())
      h.assert_eq[String](w, wild_match)
    | (None, _) =>
      h.fail("not found: " + wild_url + wild_match)
    end

primitive _TestGen
  fun url(): Generator[String] =>
    Generators.array_of[String](Generators.ascii_numeric(1, 5) where max = 5)
      .map[String]({(strs) => "/" + "/".join(strs.values())})
