use "collections"
use "ponytest"
use "ponycheck"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

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

    h.assert_error(
      {()? =>
        let radix_overmatch =
          recover val Radix[USize] .> update("/fs/*f", 0)? end
        h.log(radix_overmatch.string())
        radix_overmatch("/", Map[String, String]) as USize
      })

    h.assert_error(
      {()? =>
        let radix_split =
          recover val
            Radix[USize] .> update("/abc", 0)? .> update("/adc", 1)?
          end
        radix_split("/a", Map[String, String]) as USize
      })

    h.assert_error({()? => Radix[USize]("/*")? = 0 })
    h.assert_error({()? => Radix[USize]("/:")? = 0 })
    h.assert_error({()? => Radix[USize]("/:a/:/")? = 0 })

    let radix = Radix[Bool]
    radix("/abc")? = false
    radix("/a:bc/:d/*ef")? = true
    radix("/a:bc")? = true
    h.log(radix.string())
    let radix' = consume val radix

    let params = Map[String, String]
    match radix'("/abc", params)
    | let v: Bool => h.assert_false(v)
    | None => h.fail("not found: /abc")
    end
    h.assert_eq[USize](params.size(), 0)

    match radix'("/acb/q/fe", params)
    | let v: Bool =>
      h.assert_true(v)
      h.assert_eq[USize](params.size(), 3)
      h.assert_eq[String](params("bc")?, "cb")
      h.assert_eq[String](params("d")?, "q")
      h.assert_eq[String](params("ef")?, "fe")
    | None => h.fail("not found: /acb/q/fe")
    end
    params.clear()
    match radix'("/acb", params)
    | let v: Bool =>
      h.assert_true(v)
      h.assert_eq[USize](params.size(), 1)
      h.assert_eq[String](params("bc")?, "cb")
    | None => h.fail("not found: /acb")
    end

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
    radix(wild_url + "*w")? = 2
    radix(g(1)?)? = 1
    h.log(radix.string())
    let radix' = consume val radix

    let params = Map[String, String]
    for i in g.keys() do
      match radix'(g(i)?, params)
      | let v: USize => h.assert_eq[USize](v, i)
      | None => h.fail("not found: " + g(i)?)
      end
      h.assert_eq[USize](params.size(), 0)
    end
    match radix'(wild_url + wild_match, params)
    | let v: USize =>
      h.assert_eq[USize](v, 2)
      h.assert_eq[USize](params.size(), 1)
      h.assert_eq[String](params("w")?, wild_match)
    | None =>
      h.fail("not found: " + wild_url + wild_match)
    end

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
    radix(param_url)? = 2
    radix(g(1)?)? = 1
    h.log(radix.string())
    let radix' = consume val radix

    let params = Map[String, String]
    for i in g.keys() do
      match radix'(g(i)?, params)
      | let v: USize => h.assert_eq[USize](v, i)
      | None => h.fail("not found: " + g(i)?)
      end
      h.assert_eq[USize](params.size(), 0)
    end
    match radix'(param_base, params)
    | let v: USize =>
      h.assert_eq[USize](v, 2)
      h.assert_eq[USize](params.size(), 1)
      h.assert_eq[String](params(param_name)?, param_name)
    | None =>
      h.fail("not found: " + param_base)
    end

primitive _TestGen
  fun url(): Generator[String] =>
    Generators.array_of[String](Generators.ascii_numeric(1, 5) where max = 5)
      .map[String]({(strs) => "/" + "/".join(strs.values())})
