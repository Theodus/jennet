// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "collections"
use "encode/base64"
use "net/http"
use "ponytest"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestMultiplexer)
    test(_TestBasicAuth)

class iso _TestMultiplexer is UnitTest
  fun name(): String => "Multiplexer"

  fun apply(h: TestHelper) ? =>
    let ts = recover Array[(String, _HandlerGroup)] end
    ts.push(("/", _HandlerGroup(_TestHandler("0"))))
    ts.push(("/foo", _HandlerGroup(_TestHandler("1"))))
    ts.push(("/:foo", _HandlerGroup(_TestHandler("2"))))
    ts.push(("/foo/bar/", _HandlerGroup(_TestHandler("3"))))
    ts.push(("/baz/bar", _HandlerGroup(_TestHandler("4"))))
    ts.push(("/:foo/baz", _HandlerGroup(_TestHandler("5"))))
    ts.push(("/foo/bar/*baz", _HandlerGroup(_TestHandler("6"))))
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

    (hg, ps) = mux("GET", "/stuff") // TODO error in non-debug mode
    h.assert_eq[String]("2", (hg.handler as _TestHandler val).msg)
    h.assert_eq[String]("stuff", ps("foo"))

    h.assert_error(lambda()(mux) ? => mux("GET", "/foo/bar") end)
    (hg, ps) = mux("GET", "/foo/bar/")
    h.assert_eq[String]("3", (hg.handler as _TestHandler val).msg)

    (hg, ps) = mux("GET", "/baz/bar")
    h.assert_eq[String]("4", (hg.handler as _TestHandler val).msg)

    (hg, ps) = mux("GET", "/stuff/baz")
    h.assert_eq[String]("5", (hg.handler as _TestHandler val).msg)
    h.assert_eq[String]("stuff", ps("foo"))

    (hg, ps) = mux("GET", "/foo/bar/stuff/and/things")
    h.assert_eq[String]("6", (hg.handler as _TestHandler val).msg)
    h.assert_eq[String]("stuff/and/things", ps("baz"))

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

    let req1 = Payload.request("GET", URL.build("/"), _TestAuthResOK(h))
    let auth1 = recover val Base64.encode("test_username:test_password") end
    req1("Authorization") = "Basic " + auth1
    hg(Context(DefaultResponder(h.env.out),
      recover Map[String, String] end, "test"), consume req1)

    let req2 = Payload.request("GET", URL.build("/"),
      _TestAuthResUnauthorized(h))
    let auth2 = recover val Base64.encode("bad_username:bad_password") end
    req2("Authorization") = "Basic " + auth2
    try
      hg(Context(DefaultResponder(h.env.out),
        recover Map[String, String] end, "test"), consume req2)
    end

    h.complete(true)


class _TestHandler is Handler
  let msg: String

  new val create(msg': String) =>
    msg = msg'

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res("msg") = msg
    c.respond(consume req, consume res)
    consume c

class _TestAuthResOK is ResponseHandler
  let h: TestHelper

  new val create(h': TestHelper) =>
    h = h'

  fun val apply(request: Payload val, response: Payload val) =>
    h.assert_eq[U16](200, response.status)

class _TestAuthResUnauthorized is ResponseHandler
  let h: TestHelper

  new val create(h': TestHelper) =>
    h = h'

  fun val apply(request: Payload val, response: Payload val) =>
    h.assert_eq[U16](401, response.status)
