
// TODO docs

class _Route
  let method: String
  let path: String
  let handler: Handler
  let middleware: Array[Middleware]

  new create(method': String, path': String, handler': Handler,
    middleware': Array[Middleware])
  =>
    method = method'
    path = path'
    handler = handler'
    middleware = middleware'
