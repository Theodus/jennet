use "time"
use "net/http"

// TODO docs

class val ResponseTimer is Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) =>
    c("start_time") = Time.nanos()
    (consume c, consume req)

  fun val after(c: Context): Context iso^ =>
    consume c

primitive TimeFormat
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
