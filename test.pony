use "ponytest"
use "net/http"
use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMultiplexer)

class iso _TestMultiplexer is UnitTest
  fun name(): String => "Multiplexer"

  fun apply(h: TestHelper) ? =>
    let ts = recover Array[(String, _HandlerGroup)] end
    ts.push(("/", _HandlerGroup(_TestHandler("0"))))
    ts.push(("/foo", _HandlerGroup(_TestHandler("1"))))
    ts.push(("/:foo", _HandlerGroup(_TestHandler("2"))))
    /*
      ("/foo/bar/", _HandlerGroup(_TestHandler("3"))),
      ("/baz/bar", _HandlerGroup(_TestHandler("4"))),
      ("/:foo/baz", _HandlerGroup(_TestHandler("5")))
    ]*/
    let tests = recover val consume ts end
    let routes = recover Array[_Route] end
    for (p, hg) in tests.values() do
      routes.push(_Route("GET", p, hg))
    end
    let mux = recover val _Multiplexer(consume routes) end

    (var hg, var ps) = mux("GET", "/")
    h.assert_eq[String]("0", (hg.handler as _TestHandler val).msg)

    (hg, ps) = mux("GET", "/foo")
    h.assert_eq[String]("1", (hg.handler as _TestHandler val).msg)

    (hg, ps) = mux("GET", "/stuff")
    h.assert_eq[String]("stuff", ps("foo"))

class _TestHandler is Handler
  let msg: String

  new val create(msg': String) =>
    msg = msg'

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res("msg") = msg
    c.respond(consume req, consume res)
    consume c
