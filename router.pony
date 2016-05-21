use "net"
use "net/ssl"
use "net/http"
use "collections"

/* TODO
 - dirty routes (route correction)
 - method not allowed handler
 - internal server error
 - serve_file
 - serve_dir

Middleware:
 - basic auth
*/

// TODO docs

class val Router
  var _mux: _Multiplexer

  new val create(mux: _Multiplexer) =>
    _mux = mux

  fun val apply(request: Payload) =>
    _mux(consume request)

interface val Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) ?
  fun val after(c: Context): Context iso^

interface val Handler
  fun val apply(c: Context, req: Payload): Context iso^ ?

type Middlewares is Array[Middleware] val
