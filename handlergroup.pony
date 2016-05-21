use "net/http"

class val _HandlerGroup
  let _middlewares: Middlewares
  let _handler: Handler

  new val create(middlewares: Middlewares, handler: Handler) =>
    _middlewares = middlewares
    _handler = handler

  fun val apply(c: Context, req: Payload) ? =>
    match _middlewares.size()
    | 0 =>
      _handler(consume c, consume req)
    else
      (let c', let req') = _middlewares_apply(0, consume c, consume req)
      _middlewares_after(_middlewares.size() - 1,
        _handler(consume c', consume req'))
    end

  fun val _middlewares_apply(i: USize, c: Context, req: Payload):
    (Context iso^, Payload iso^) ?
  =>
    match i
    | _middlewares.size() => (consume c, consume req)
    else
      (let c', let req') = _middlewares(i)(consume c, consume req)
      _middlewares_apply(i + 1, consume c', consume req')
    end

  fun _middlewares_after(i: USize, c: Context): Context iso^ ? =>
    match i
    | -1 => consume c
    else
      _middlewares_after(i - 1, _middlewares(i).after(consume c))
    end
