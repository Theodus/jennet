use "collections"
use "http"
use "time"

class iso Context
  """
  Contains the data passed between middleware and the handler.
  """
  let _responder: Responder
  let _params: Map[String, String] val
  let _data: Map[String, Any val]
  let _start_time: U64

  new iso create(responder': Responder, params': Map[String, String] val) =>
    _responder = responder'
    _params = params'
    _data = Map[String, Any val]
    _start_time = Time.nanos()

  fun ref param(key: String): String val =>
    """
    Get the URL parameter corresponding to key, return an empty String if not
    found.
    """
    try
      _params(key)?
    else
      ""
    end

  fun ref get(key: String): Any val ? =>
    """
    Get the data corresponding to key.
    """
    _data(key)?

  fun ref update(key: String, value: Any val) =>
    """
    Place a key-value pair into the context, updating any existing pair with the
    same key.
    """
    _data(key) = value

  fun ref respond(req: Payload val, res: Payload val) =>
    """
    Respond to the given request with the response.
    """
    let response_time = Time.nanos() - _start_time
    _responder(req, res, response_time)
