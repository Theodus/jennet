use "collections"
use "net/http"

class iso Context
  """
  Contains the data passed between middleware and the handler.
  """
  let _responder: Responder
  let _params: Map[String, String]
  let _data: Map[String, Any val]

  new iso create(responder': Responder, params': Map[String, String] iso) =>
    _responder = responder'
    _params = consume params'
    _data = Map[String, Any val]

  fun val param(key: String): String val ? =>
    """
    Get the URL parameter corresponding to key.
    """
    _params(key)

  fun val get(key: String): Any val ? =>
    """
    Get the data corresponding to key.
    """
    _data(key)

  fun ref update(key: String, value: Any val) =>
    """
    Place a key-value pair into the context, updating any existing pair with the
    same key.
    """
    _data(key) = value

  fun ref respond(req: Payload iso, res: Payload iso) =>
    """
    Respond to the given request with the response.
    """
    let response_time = try
      let st = _data("start_time") as U64
      TimeFormat(st)
    else
      "-----"
    end
    _responder(consume req, consume res, response_time)
