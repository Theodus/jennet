use "collections"
use "net/http"

// TODO docs

class iso Context
  let _params: Map[String, String]
  let _data: Map[String, Any]
  let _logger: ResponseLogger

  new iso create(params': Map[String, String] iso, data': Map[String, Any] iso,
    logger': ResponseLogger)
  =>
    _params = consume params'
    _data = consume data'
    _logger = logger'

  fun val param(key: String): String val ? =>
    _params(key)

  fun val get(key: String): Any ? =>
    _data(key)

  fun ref update(key: String, value: Any) =>
    _data.update(key, value)

  fun ref respond(req: Payload iso, res: Payload iso) =>
    _logger(req.method, req.url.path, res.proto, res.status, res.body_size())
    (consume req).respond(consume res)
