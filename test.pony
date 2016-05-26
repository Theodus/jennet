use "ponytest"
use "collections"
use "net/http"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMultiplexer)

class iso _TestMultiplexer is UnitTest
  fun name(): String => "_Multiplexer"

  fun apply(h: TestHelper) ? =>
    let ts = _TestStream

    let path0 = "/"
    let h0 = _TestHandler(0, ts)
    let path1 = "/foo"
    let hg1 = _HandlerGroup(_TestHandler(1, ts))
    let path2 = "/foo/"
    let hg2 = _HandlerGroup(_TestHandler(2, ts))
    let path3 = "/:foo/"
    let hg3 = _HandlerGroup(_TestHandler(3, ts))
    let path4 = "/:foo/bar/baz"
    let hg4 = _HandlerGroup(_TestHandler(4, ts))
    let path5 = "/foo/bar"
    let hg5 = _HandlerGroup(_TestHandler(5, ts))

    let rb = RouteBuilder(ts)
    rb.get(path0, h0)
    let router = (consume rb).build()
    router(Payload.request("GET", URL.build(path0)))
    // TODO
    let params = Map[String, String]
    //h.assert_eq[(_HandlerGroup, Map[String, String])]((hg0, params), t)

class val _TestHandler is Handler
  let _id: USize
  let _ts: _TestStream

  new val create(id: USize, ts: _TestStream) =>
    _id = id
    _ts = ts

  fun val apply(c: Context, req: Payload): Context iso^ =>
    _ts.print(_id.string())
    consume c

actor _TestStream is OutStream
  let _data: String ref = recover String end

  be print(data: (String val | Array[U8 val] val)) =>
    _data.append(data)
    _data.append("\n")

  be write(data: (String val | Array[U8 val] val)) =>
    _data.append(data)

  be printv(data: ByteSeqIter val) =>
    for bs in data.values() do
      _data.append(bs)
      _data.append("\n")
    end

  be writev(data: ByteSeqIter val) =>
    for bs in data.values() do
      _data.append(bs)
    end
