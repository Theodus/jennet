use "net/http"
/*
actor _Responder
  be apply(request: Payload, mux: _Multiplexer) =>
    try
      mux(consume request)
    else
      internal_server_error(consume request)
    end

  be not_found(request: Payload) =>
    let res = Payload.response(404, "Not Found")
    res.add_chunk("404: Not Found")
    (consume request).respond(consume res)

  be internal_server_error(request: Payload) =>
    let res = Payload.response(500, "Internal Server Error")
    res.add_chunk("500: Internal Server Error")
    (consume request).respond(consume res)

  be service_unavailable(request: Payload) =>
    let res = Payload.response(503, "Service Unavailable")
    res.add_chunk("503: Service Unavailable")
    (consume request).respond(consume res)
*/
