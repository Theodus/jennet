use "collections"
use "net/http"

// TODO docs

class iso Context
  let _params: Map[String, String]
  let _data: Map[String, Any]

  new iso create(params': Map[String, String] iso, data': Map[String, Any] iso)
  =>
    _params = consume params'
    _data = consume data'

  fun val param(key: String): String val ? =>
    _params(key)

  fun val get(key: String): Any ? =>
    _data(key)

  fun ref update(key: String, value: Any) =>
    _data.update(key, value)
