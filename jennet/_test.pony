use "collections"
use "encode/base64"
use "http"
use "ponytest"
use radix = "radix"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    radix.Main.make().tests(test)
    test(_TestBasicAuth)

class iso _TestBasicAuth is UnitTest
  fun name(): String => "BasicAuth"

  fun apply(h: TestHelper) ? =>
    let mw = recover Array[Middleware](1) end
    let accounts = recover val
      let m = Map[String, String]
      m("test_username") = "test_password"
      m
    end
    mw.push(BasicAuth("test", accounts))
    let hg = _HandlerGroup(_TestHandler("auth"), consume mw)

    h.long_test(1_000_000_000)

    let req1 = Payload.request("GET", URL.build("/")?)
    let auth1 = recover val Base64.encode("test_username:test_password") end
    req1("Authorization") = "Basic " + auth1
    hg(Context(_TestAuthResOK(h),
      recover Map[String, String] end), consume req1)?

    let req2 = Payload.request("GET", URL.build("/")?)
    let auth2 = recover val Base64.encode("bad_username:bad_password") end
    req2("Authorization") = "Basic " + auth2
    try
      hg(Context(_TestAuthResUnauthorized(h),
        recover Map[String, String] end), consume req2)?
    end

    h.complete(true)


class _TestHandler is Handler
  let msg: String

  new val create(msg': String) =>
    msg = msg'

  fun val apply(c: Context, req: Payload val): Context iso^ =>
    let res = Payload.response()
    res("msg") = msg
    c.respond(req, consume res)
    consume c

class _TestAuthResOK is Responder
  let h: TestHelper

  new val create(h': TestHelper) =>
    h = h'

  fun apply(request: Payload val, response: Payload val, response_time: U64) =>
    h.assert_eq[U16](200, response.status)

class _TestAuthResUnauthorized is Responder
  let h: TestHelper

  new val create(h': TestHelper) =>
    h = h'

  fun apply(request: Payload val, response: Payload val, respone_time: U64) =>
    h.assert_eq[U16](401, response.status)
