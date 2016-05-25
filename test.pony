use "ponytest"
use "net/http"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMultiplexer)

class iso _TestMultiplexer is UnitTest
  fun name(): String => "_Multiplexer"

  fun apply(h: TestHelper) ? =>
    // TODO
    error

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

  fun ref str(): String ref => _data
