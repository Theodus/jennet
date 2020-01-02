use "collections"
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestRadix)
    test(Property1UnitTest[Array[String]](_TestRadixBasic))
    test(Property1UnitTest[Array[String]](_TestRadixWild))
    test(Property1UnitTest[Array[String]](_TestRadixParam))

class _TestRadix is UnitTest
  fun name(): String =>
    "radix/tree"

  fun apply(h: TestHelper) ? =>
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

    h.assert_error({()? => Radix[USize]("/*")? = 0 })
    h.assert_error({()? => Radix[USize]("/:")? = 0 })

class _TestRadixBasic is Property1[Array[String]]
  fun name(): String =>
    "radix/basic"

  fun gen(): Generator[Array[String]] =>
    Generators.array_of[String](_TestGen.url() where max = 100)

  fun property(g: Array[String], h: PropertyHelper) ? =>
    let table = Map[String, USize]
    let radix = Radix[USize]

    for (i, url) in g.pairs() do
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

class _TestRadixWild is Property1[Array[String]]
  fun name(): String =>
    "radix/wild"

  fun gen(): Generator[Array[String]] =>
    Generators.array_of[String](_TestGen.url() where min = 4, max = 4)

  fun property(g: Array[String], h: PropertyHelper) ? =>
    if g(0)? == g(1)? then return end
    let wild_url = g.pop()?
    let wild_match = g.pop()?

    let radix = Radix[USize]
    radix(g(0)?)? = 0
    radix(wild_url + "*w")? = 1
    radix(g(1)?)? = 2
    h.log(radix.string())
    let radix' = consume val radix

    let params = Map[String, String]
    h.assert_eq[USize](radix'(g(0)?, params) as USize, 0)
    h.assert_eq[USize](params.size(), 0)
    h.assert_eq[USize](radix'(g(1)?, params) as USize, 2)
    h.assert_eq[USize](params.size(), 0)
    h.assert_eq[USize](radix'(wild_url + wild_match, params) as USize, 1)
    h.assert_eq[USize](params.size(), 1)
    h.assert_eq[String](params("w")?, wild_match)

class _TestRadixParam is Property1[Array[String]]
  fun name(): String =>
    "radix/param"

  fun gen(): Generator[Array[String]] =>
    Generators.array_of[String](_TestGen.url() where min = 3, max = 3)

  fun property(g: Array[String], h: PropertyHelper) ? =>
    if g(0)? == g(1)? then return end
    let param_base = g.pop()?
    if param_base.count("/") < 2 then return end

    let param_start = param_base.find("/" where nth = 1)? + 1
    let param_end =
      try param_base.find("/", param_start)? else ISize.max_value() end
    let param_name: String = param_base.substring(param_start, param_end)
    let param_url: String = param_base.insert(param_start, ":")

    let radix = Radix[USize]
    radix(g(0)?)? = 0
    radix(param_url)? = 1
    radix(g(1)?)? = 2
    h.log(radix.string())
    let radix' = consume val radix

    let params = Map[String, String]
    h.assert_eq[USize](radix'(g(0)?, params) as USize, 0)
    h.assert_eq[USize](params.size(), 0)
    h.assert_eq[USize](radix'(g(1)?, params) as USize, 2)
    h.assert_eq[USize](params.size(), 0)
    h.assert_eq[USize](radix'(param_base, params) as USize, 1)
    h.assert_eq[USize](params.size(), 1)
    h.assert_eq[String](params(param_name)?, param_name)

primitive _TestGen
  fun url(): Generator[String] =>
    Generators.array_of[String](Generators.ascii_numeric(1, 5) where max = 5)
      .map[String]({(strs) => "/" + "/".join(strs.values())})
