use "net/http"

class val _HandlerGroup
  let middlewares: Middlewares
  let handler: Handler

  new val create(handler': Handler,
    middlewares': Middlewares = recover Array[Middleware] end)
  =>
    middlewares = middlewares'
    handler = handler'

  fun val apply(c: Context, req: Payload) ? =>
    match middlewares.size()
    | 0 =>
      handler(consume c, consume req)
    else
      (let c', let req') = middlewares_apply(0, consume c, consume req)
      middlewares_after(middlewares.size() - 1,
        handler(consume c', consume req'))
    end

  fun val middlewares_apply(i: USize, c: Context, req: Payload):
    (Context iso^, Payload iso^) ?
  =>
    match i
    | middlewares.size() => (consume c, consume req)
    else
      (let c', let req') = middlewares(i)(consume c, consume req)
      middlewares_apply(i + 1, consume c', consume req')
    end

  fun middlewares_after(i: USize, c: Context): Context iso^ ? =>
    match i
    | -1 => consume c
    else
      middlewares_after(i - 1, middlewares(i).after(consume c))
    end
