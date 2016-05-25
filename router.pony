use "net/http"

class val Router
  """
  Routes incomming requests to the corresponding middlewares and handler.
  """
  var _mux: _BadMultiplexer

  new val create(mux: _BadMultiplexer) =>
    _mux = mux

  fun val apply(request: Payload) =>
    _mux(consume request)

// TODO middleware callbacks rather than chains?

interface val Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) ?
  fun val after(c: Context): Context iso^

interface val Handler
  fun val apply(c: Context, req: Payload): Context iso^ ?

type Middlewares is Array[Middleware] val
