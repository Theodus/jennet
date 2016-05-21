use "collections"
use "net/http"

// TODO docs

class iso Context
  let _params: Map[String, String]
  let _data: Map[String, Any val]
  let _logger: ResponseLogger

  new iso create(params': Map[String, String] iso, logger': ResponseLogger) =>
    _params = consume params'
    _data = Map[String, Any val]
    _logger = logger'

  fun val param(key: String): String val ? =>
    _params(key)

  fun val get(key: String): Any ? =>
    _data(key)

  fun ref update(key: String, value: Any val) =>
    _data(key) = value

  fun ref respond(req: Payload iso, res: Payload iso) =>
    let response_time = try
      let st = _data("start_time") as U64
      TimeFormat(st)
    else
      ""
    end
    _logger(req.method, req.url.path, res.proto, res.status, res.body_size(),
      response_time)
    (consume req).respond(consume res)
