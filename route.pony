
class val _Route
  let method: String
  let path: String
  let handler: Handler
  let middlewares: Middlewares

  new val create(method': String, path': String, handler': Handler,
    middlewares': Middlewares)
  =>
    method = method'
    path = path'
    handler = handler'
    middlewares = middlewares'
