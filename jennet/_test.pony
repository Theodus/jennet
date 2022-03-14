use "collections"
use "encode/base64"
use "http_server"
use "pony_test"
use radix = "radix"
use "valbytes"

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

    let auth1 = Base64.encode("test_username:test_password")
    let req1 =
      recover val
        BuildableRequest(where uri' = URL.build("/")?)
          .add_header("Authorization", "Basic " + consume auth1)
      end
    hg(
      Context(
        _TestAuthRes(h, StatusOK),
        recover Map[String, String] end,
        _TestHTTPSession,
        0,
        consume req1,
        ByteArrays))?

    let auth2 = Base64.encode("bad_username:bad_password")
    let req2 =
      recover val
        BuildableRequest(where uri' = URL.build("/")?)
          .add_header("Authorization", "Basic " + consume auth2)
      end
    try
      hg(
        Context(
          _TestAuthRes(h, StatusUnauthorized),
          recover Map[String, String] end,
          _TestHTTPSession,
          0,
          consume req2,
          ByteArrays))?
    end

    h.complete(true)


class _TestHandler is RequestHandler
  let msg: String

  new val create(msg': String) =>
    msg = msg'

  fun val apply(ctx: Context): Context iso^ =>
    ctx.respond(StatusResponse(StatusOK))
    consume ctx

class _TestAuthRes is Responder
  let h: TestHelper
  let status: Status

  new val create(h': TestHelper, status': Status) =>
    h = h'
    status = status'

  fun apply(res: Response, body: ByteArrays, ctx: Context box) =>
    h.assert_is[Status](status, res.status())

actor _TestHTTPSession is Session
  be _receive_start(request: Request val, request_id: RequestID) => None
  be _receive_chunk(data: Array[U8] val, request_id: RequestID) => None
  be _receive_finished(request_id: RequestID) => None
  be dispose() => None
  be _mute() => None
  be _unmute() => None
  be send_start(response: Response val, request_id: RequestID) => None
  be send_cancel(request_id: RequestID) => None
  be send_finished(request_id: RequestID) => None
  be send(response: Response val, body: ByteArrays, request_id: RequestID) => None
  be send_chunk(data: ByteSeq val, request_id: RequestID) => None
  be send_no_body(response: Response val, request_id: RequestID) => None
  be send_raw(raw: ByteSeqIter, request_id: RequestID, close_session: Bool = false) => None
