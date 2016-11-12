// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "collections"
use "net/http"

class val _Router
  let _mux: _Multiplexer
  let _responder: Responder
  let _notfound: _HandlerGroup

  new val create(mux: _Multiplexer, responder: Responder,
    notfound: _HandlerGroup)
  =>
    _mux = consume mux
    _responder = responder
    _notfound = notfound

  fun val apply(request: Payload) =>
    (let hg, let c) = try
      (let hg, let params) = _mux(request.method, request.url.path)
      let c = Context(_responder, consume params)
      (hg, consume c)
    else
      (_notfound, Context(_responder, recover Map[String, String] end))
    end
    try
      hg(consume c, consume request)
    end

primitive _Unavailable
  fun apply(request: Payload) =>
    let res = Payload.response(StatusServiceUnavailable)
    (consume request).respond(consume res)

class val _Route
  let method: String
  let path: String
  let hg: _HandlerGroup

  new val create(method': String, path': String, hg': _HandlerGroup)
  =>
    method = method'
    path = path'
    hg = hg'
