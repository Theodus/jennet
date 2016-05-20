use "collections"
use "net/http"

// TODO docs

class iso Context
  let _request: Payload
  let _params: Map[String, String]
  let _data: Map[String, Any]

  new iso create(request': Payload iso, params': Map[String, String] iso,
    data': Map[String, Any] iso)
  =>
    _request = consume request'
    _params = consume params'
    _data = consume data'

  fun val param(key: String): String val ? =>
    _params(key)

  fun val get(key: String): Any ? =>
    _data(key)

  fun ref update(key: String, value: Any) =>
    _data.update(key, value)

  // TODO more response options
  fun iso respond_string(msg: String) =>
    let res = recover Payload.response() end
    res.add_chunk(msg)
    (consume this)._request.respond(consume res)
