use "collections"
use http = "net/http"

class iso Context
  // TODO docs
  let _request: http.Payload
  let _params: Params
  let _data: Map[String, Any]

  new iso create(request': http.Payload iso, params': Params,
    data': Map[String, Any] iso)
  =>
    _request = consume request'
    _params = consume params'
    _data = consume data'

  // TODO box or val ?
  fun box request(): this->http.Payload => _request

  fun val param(key: String): String val ? => _params(key)

  fun val get(key: String): Any ? => _data(key)

  fun ref update(key: String, value: Any) => _data.update(key, value)

type Params is Map[String val, String val] iso
