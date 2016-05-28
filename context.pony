// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "collections"
use "net/http"

// TODO docs
// TODO JSON integration
// TODO Separate map in context for iso values?

use "time"

class iso Context
  """
  Contains the data passed between middleware and the handler.
  """
  let _responder: Responder
  let _params: Map[String, String]
  let _data: Map[String, Any val]
  let _host: String
  let _start_time: U64

  new iso create(responder': Responder, params': Map[String, String] iso,
    host': String)
  =>
    _responder = responder'
    _params = consume params'
    _data = Map[String, Any val]
    _host = host'
    _start_time = Time.nanos()

  fun ref param(key: String): String val ? =>
    """
    Get the URL parameter corresponding to key.
    """
    _params(key)

  fun ref get(key: String): Any val ? =>
    """
    Get the data corresponding to key.
    """
    _data(key)

  fun ref update(key: String, value: Any val) =>
    """
    Place a key-value pair into the context, updating any existing pair with the
    same key.
    """
    _data(key) = value

  fun ref respond(req: Payload iso, res: Payload iso) =>
    """
    Respond to the given request with the response.
    """
    let response_time = TimeFormat(_start_time, Time.nanos())
    _responder(consume req, consume res, response_time, _host)

primitive TimeFormat
  """
  Formats the time difference between the current time and the start time so
  that the correct units of time are logged.
  """
  fun apply(start_time: U64, end_time: U64): String =>
    let time = (end_time - start_time).string()
    let s = time.size()
    if s < 4 then
      time + "ns"
    elseif s < 7 then
      time.substring(0, s.isize() - 3) + "µs"
    elseif s < 10 then
      time.substring(0, s.isize() - 6) + "ms"
    else
      time.substring(0, s.isize() - 9) + "s"
    end
