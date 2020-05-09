use "collections"
use "http/server"
use "time"
use "valbytes"

class iso Context
  """
  Contains the data passed between middleware and the handler.
  """
  let _responder: Responder
  let params: Map[String, String] val
  let data: Map[String, Any val]
  let start_time: U64
  let session: Session
  let request_id: RequestID
  let request: Request
  let body: ByteArrays

  new iso create(
    responder': Responder,
    params': Map[String, String] val,
    session': Session,
    request_id': RequestID,
    request': Request,
    body': ByteArrays)
  =>
    _responder = responder'
    params = params'
    data = Map[String, Any val]
    start_time = Time.nanos()
    session = session'
    request_id = request_id'
    request = request'
    body = body'

  fun ref param(key: String): String =>
    """
    Get the URL parameter corresponding to key, return an empty String if not
    found.
    """
    try
      params(key)?
    else
      ""
    end

  fun ref get(key: String): Any val ? =>
    """
    Get the data corresponding to key.
    """
    data(key)?

  fun ref update(key: String, value: Any val) =>
    """
    Place a key-value pair into the context, updating any existing pair with the
    same key.
    """
    data(key) = value

  fun ref respond(res: Response, res_body: ValBytes = []) =>
    """
    Respond to the given request with the response.
    """
    _responder(res, ByteArrays(res_body), this)
