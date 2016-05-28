// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "time"
use "net/http"

class val ResponseTimer is Middleware
  """
  Places start time in the context.
  """
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) =>
    c("start_time") = Time.nanos()
    (consume c, consume req)

  fun val after(c: Context): Context iso^ =>
    consume c

primitive TimeFormat
  """
  Formats the time difference between the current time and the start time so
  that the correct units of time are logged.
  """
  fun apply(start_time: U64): String =>
    let end_time = Time.nanos()
    let time = (end_time - start_time).string()
    let s = time.size()
    if s < 4 then
      time + "ns"
    elseif s < 7 then
      time.substring(0, 3) + "µs"
    elseif s < 10 then
      time.substring(0, 3) + "ms"
    else
      time.substring(0, s.isize() - 9) + "s"
    end
