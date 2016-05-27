use "net/http"
use "collections"

class _Router
  let _mux: _Multiplexer
  let _responder: Responder
  let _notfound: _HandlerGroup
  let _host: String

  new val create(mux: _Multiplexer, responder: Responder,
    notfound: _HandlerGroup, host: String)
  =>
    _mux = consume mux
    _responder = responder
    _notfound = notfound
    _host = host

  fun val apply(request: Payload) =>
    (let hg, let c) = try
      (let hg, let params) = _mux(request.method, request.url.path)
      let c = Context(_responder, consume params, _host)
      (hg, consume c)
    else
      (_notfound, Context(_responder, recover Map[String, String] end, _host))
    end
    try
      hg(consume c, consume request)
    end

class _Unavailable
  fun val apply(request: Payload) =>
    let res = Payload.response(503, "Service Unavailable")
    (consume request).respond(consume res)
