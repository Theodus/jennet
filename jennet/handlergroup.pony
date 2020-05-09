use "http/server"

class val _HandlerGroup
  let middlewares: Array[Middleware] val
  let handler: RequestHandler

  new val create(handler': RequestHandler, middlewares': Array[Middleware] val = [])
  =>
    middlewares = middlewares'
    handler = handler'

  fun val apply(ctx: Context) ? =>
    match middlewares.size()
    | 0 =>
      handler(consume ctx)?
    else
      let ctx' = middlewares_apply(0, consume ctx)?
      middlewares_after(
        middlewares.size() - 1,
        handler(consume ctx')?
      )?
    end

  fun val middlewares_apply(i: USize, ctx: Context)
    : Context iso^ ?
  =>
    match i
    | middlewares.size() => consume ctx
    else
      let ctx' = middlewares(i)?(consume ctx)?
      middlewares_apply(i + 1, consume ctx')?
    end

  fun middlewares_after(i: USize, ctx: Context): Context iso^ ? =>
    match i
    | -1 => consume ctx
    else
      middlewares_after(i - 1, middlewares(i)?.after(consume ctx))?
    end
