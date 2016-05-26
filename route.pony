
class val _Route
  let method: String
  let path: String
  let hg: _HandlerGroup

  new val create(method': String, path': String, hg': _HandlerGroup)
  =>
    method = method'
    path = path'
    hg = hg'
