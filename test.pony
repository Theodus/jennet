use "ponytest"
use "net/http"
use "collections"
use "promises"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMultiplexer)

class iso _TestMultiplexer is UnitTest
  fun name(): String => "_Multiplexer"

  fun apply(h: TestHelper) ? =>
    error

class val _TestHandler is Handler
  let msg: String

  new create(msg': String) =>
    msg = msg'

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res("msg") = msg
    c.respond(consume req, consume res)
    consume c
