use "net/http"

// TODO docs

interface val Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^)
  fun val after(c: Context): Context iso^

interface val Handler
  fun val apply(c: Context, req: Payload): Context iso^


class _HandlerGroup
  let _middleware: Array[Middleware]
  let _handler: Handler

  new create(middleware: Array[Middleware], handler: Handler) =>
    _middleware = middleware
    _handler = handler

  fun apply(c: Context, req: Payload) ? =>
    match _middleware.size()
    | 0 =>
      _handler(consume c, consume req)
    else
      (let c', let req') = _middleware_apply(0, consume c, consume req)
      _middleware_after(_middleware.size() - 1,
        _handler(consume c', consume req'))
    end

  fun _middleware_apply(i: USize, c: Context, req: Payload):
    (Context iso^, Payload iso^) ?
  =>
    match i
    | _middleware.size() => (consume c, consume req)
    else
      (let c', let req') = _middleware(i)(consume c, consume req)
      _middleware_apply(i + 1, consume c', consume req')
    end

  fun _middleware_after(i: USize, c: Context): Context iso^ ? =>
    match i
    | 0 => consume c
    else
      _middleware_after(i - 1, _middleware(i).after(consume c))
    end
