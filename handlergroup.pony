
class _HandlerGroup
  let _middleware: Array[Middleware]
  let _handler: Handler

  new create(middleware: Array[Middleware], handler: Handler) =>
    _middleware = middleware
    _handler = handler

  fun apply(c: Context) ? =>
    let c' = match _middleware.size()
    | 0 => consume c
    else
      _exec_middleware(0, consume c)
    end
    _handler(consume c')

  fun _exec_middleware(i: USize, c: Context): Context iso^ ? =>
    match i
    | _middleware.size() => consume c
    else
      _exec_middleware(i + 1, _middleware(i)(consume c))
    end
