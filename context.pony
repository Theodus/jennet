use "collections"
use http = "net/http"

class iso Context
  let _request: http.Payload
  let _params: Params

  new iso create(request': http.Payload iso, params': Params) =>
    _request = consume request'
    _params = consume params'

  fun request(): http.Payload tag => _request

  fun params(): Params tag => _params


type Params is Map[String val, String val] iso
