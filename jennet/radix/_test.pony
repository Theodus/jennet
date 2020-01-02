use "collections"
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestRadix)
    test(Property1UnitTest[Array[String]](_TestRadixBasic))
    test(Property1UnitTest[Array[String]](_TestWild))

class _TestRadix is UnitTest
  fun name(): String =>
    "radix/tree"

  fun apply(h: TestHelper) ? =>
    h.assert_error({()? => Radix[USize]("/*")? = 0 })

    let tests = ["/"; "/abc"; "/abc/"; "/def"]
    for path in tests.values() do
      let radix =
        recover val Radix[USize] .> update("/abc", 0)? .> update(path, 1)? end
      let check_path =
        {(path: String, v: USize) ? =>
          let params = Map[String, String]
          if (radix(path, params) as USize) != v then error end
          if params.size() != 0 then error end
        }
      h.log(radix.string())
      check_path("/abc", if path == "/abc" then 1 else 0 end)?
      check_path(path, 1)?
    end

class _TestRadixBasic is Property1[Array[String]]
  fun name(): String =>
    "radix/basic"

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
    let radix' = consume val radix

    for (k, v) in table.pairs() do
      let params = Map[String, String]
      match radix'(k, params)
      | let v': USize => h.assert_eq[USize](v, v')
      | None => h.fail("not found: " + k)
      end
      h.assert_eq[USize](params.size(), 0)
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
    radix(wild_url + "*w")? = a.size()
    h.log(radix.string())
    let radix' = consume val radix

    let params = Map[String, String]
    for (k, v) in table.pairs() do
      match radix'(k, params)
      | let v': USize => h.assert_eq[USize](v', v)
      | None => h.fail("not found: " + k)
      end
      h.assert_eq[USize](params.size(), 0)
    end
    match radix'(wild_url + wild_match, params)
    | let v': USize =>
      h.assert_eq[USize](v', a.size())
      h.assert_eq[String](params("w")?, wild_match)
    | None =>
      h.fail("not found: " + wild_url + wild_match)
    end

primitive _TestGen
  fun url(): Generator[String] =>
    Generators.array_of[String](Generators.ascii_numeric(1, 5) where max = 5)
      .map[String]({(strs) => "/" + "/".join(strs.values())})
