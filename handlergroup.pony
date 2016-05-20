use "net/http"

class _HandlerGroup
  let _middlewares: Middlewares
  let _handler: Handler

  new create(middlewares: Middlewares, handler: Handler) =>
    _middlewares = middlewares
    _handler = handler

  fun apply(c: Context, req: Payload) ? =>
    match _middlewares.ms.size()
    | 0 =>
      _handler(consume c, consume req)
    else
      (let c', let req') = _middlewares_apply(0, consume c, consume req)
      _middlewares_after(_middlewares.ms.size() - 1,
        _handler(consume c', consume req'))
    end

  fun _middlewares_apply(i: USize, c: Context, req: Payload):
    (Context iso^, Payload iso^) ?
  =>
    match i
    | _middlewares.ms.size() => (consume c, consume req)
    else
      (let c', let req') = _middlewares.ms(i)(consume c, consume req)
      _middlewares_apply(i + 1, consume c', consume req')
    end

  fun _middlewares_after(i: USize, c: Context): Context iso^ ? =>
    match i
    | 0 => consume c
    else
      _middlewares_after(i - 1, _middlewares.ms(i).after(consume c))
    end
