// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "collections"
use "http"

class val _Router is HTTPHandler
  let _mux: _Multiplexer val
  let _responder: Responder
  let _notfound: _HandlerGroup

  new create(mux: _Multiplexer val, responder: Responder,
    notfound: _HandlerGroup)
  =>
    _mux = mux
    _responder = responder
    _notfound = notfound

  fun ref apply(request: Payload val) =>
    (let hg, let c) = try
      (let hg, let params) = _mux(request.method, request.url.path)?
      let c = Context(_responder, consume params)
      (hg, consume c)
    else
      (_notfound, Context(_responder, recover Map[String, String] end))
    end
    try
      hg(consume c, consume request)?
    end

primitive _UnavailableFactory is HandlerFactory
  fun apply(session: HTTPSession): HTTPHandler ref^ =>
    object is HTTPHandler
      fun ref apply(request: Payload val) =>
        let res = Payload.response(StatusServiceUnavailable)
        session(consume res)
    end

class val _Route
  let method: String
  let path: String
  let hg: _HandlerGroup

  new val create(method': String, path': String, hg': _HandlerGroup)
  =>
    method = method'
    path = path'
    hg = hg'
