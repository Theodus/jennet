use "collections"
use "http_server"
use "valbytes"

type _ReqData is
  (_HandlerGroup, Request, Map[String, String] val, ByteArrays)

class val _Router is Handler
  let _mux: _Mux
  let _responder: Responder
  let _notfound: _HandlerGroup
  let _session: Session
  embed _reqs: Map[RequestID, _ReqData] = Map[RequestID, _ReqData]

  new create(mux: _Mux, responder: Responder, notfound: _HandlerGroup, session: Session) =>
    _mux = mux
    _responder = responder
    _notfound = notfound
    _session = session

  fun ref apply(req: Request, id: RequestID) =>
    (let hg, let params: Map[String, String] val) =
      recover
        let params = Map[String, String]
        match _mux(req.method().string(), req.uri().path, params)
        | let hg: _HandlerGroup => (hg, params)
        | None => (_notfound, params)
        end
      end
    _reqs(id) = (hg, req, params, ByteArrays)

  fun ref chunk(data: ByteSeq val, id: RequestID) =>
    try
      let req = _reqs(id)?
      _reqs(id) = (req._1, req._2, req._3, req._4 + data)
    end

  fun ref finished(id: RequestID) =>
    try
      (_, (let hg, let req, let params, let body)) = _reqs.remove(id)?
      hg(Context(_responder, params, _session, id, req, body))?
    else
      _session.dispose()
    end

  fun ref cancelled(id: RequestID) =>
    try _reqs.remove(id)? end

  fun ref failed(reason: RequestParseError, id: RequestID) =>
    // TODO: respond with bad request and close
    try
      _reqs.remove(id)?
      _session.dispose()
    end

primitive _UnavailableFactory is HandlerFactory
  fun apply(session: Session): Handler ref^ =>
    object is Handler
      fun ref apply(request: Request, id: RequestID) =>
        session.send_no_body(StatusResponse(StatusServiceUnavailable), id)
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
