use "collections"
use "http"

class val _Router is HTTPHandler
  let _mux: _Mux
  let _responder: Responder
  let _notfound: _HandlerGroup

  new create(mux: _Mux, responder: Responder, notfound: _HandlerGroup) =>
    _mux = mux
    _responder = responder
    _notfound = notfound

  fun ref apply(request: Payload val) =>
    (let hg, let params: Map[String, String] val) =
      recover
        let params = Map[String, String]
        match _mux(request.method, request.url.path, params)
        | let hg: _HandlerGroup => (hg, params)
        | None => (_notfound, params)
        end
      end
    try
      hg(Context(_responder, consume params), consume request)?
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
