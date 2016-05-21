use "collections"
use "net/http"

// TODO docs

class iso Context
  let _responder: Responder
  let _params: Map[String, String]
  let _data: Map[String, Any val]

  new iso create(responder': Responder, params': Map[String, String] iso) =>
    _responder = responder'
    _params = consume params'
    _data = Map[String, Any val]

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
      "-----"
    end
    _responder(consume req, consume res, response_time)
