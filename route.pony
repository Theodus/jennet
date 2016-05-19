
// TODO docs

interface Middleware
  fun apply(c: Context): Context iso^

interface Handler
  fun apply(c: Context): Any tag

class Route
  let _method: String
  let _path: String
  let _handler: Handler
  let _middleware: Array[Middleware]

  new _create(method': String, path': String, handler': Handler,
    middleware': Array[Middleware])
  =>
    _method = method'
    _path = path'
    _handler = handler'
    _middleware = middleware'

  fun ref set(mw: Array[Middleware]) =>
    for m in mw.values() do
      _middleware.push(m)
    end

  fun method(): String =>
    _method

  fun path(): String =>
    _path

  fun handler(): this->Handler =>
    _handler

  fun middleware(): this->Array[Middleware] =>
    _middleware
