use "net"
use "http"
use "term"
use "time"
use "valbytes"

interface val Responder
  """
  Responds to the request and creates a log.
  """
  fun apply(res: Response, body: ByteArrays, ctx: Context box)

class val DefaultResponder is Responder
  let _out: OutStream
  let _host: String

  new val create(out: OutStream) =>
    _out = out
    _host =
      try
        (let host, let service) = NetAddress.name()?
        ":".join([host; service].values())
      else
        "Jennet" // TODO get IP from server
      end

  fun apply(res: Response, body: ByteArrays, ctx: Context box)
  =>
    ctx.session.send(res, body, ctx.request_id)
    match res.header("Connection")
    | let h: String if h.contains("close") => ctx.session.dispose()
    end

    let response_time = Time.nanos() - ctx.start_time
    let time = try PosixDate(Time.seconds()).format("%d/%b/%Y %H:%M:%S")? else "ERROR" end
    let status = res.status()()
    _out.writev(
      [ "["; _host; "] "; time; " |"
        if (status >= 200) and (status < 300) then
          ANSI.bright_green()
        elseif (status >= 300) and (status < 400) then
          ANSI.bright_blue()
        elseif (status >= 400) and (status < 500) then
          ANSI.bright_yellow()
        else
          ANSI.bright_red()
        end
        status.string(); ANSI.reset()
        "| "; _format_time(response_time); " | "; ctx.request.method().repr()
        " "; ctx.request.uri().path; "\n"
      ])

  fun _format_time(response_time: U64): String =>
    var padding = "       "
    let time = recover response_time.string() end
    var unit = "ns"
    let s = time.size()

    if s < 4 then
      None
    elseif s < 7 then
      time.insert_in_place(s.isize() - 3, ".")
      unit = "µs"
    elseif s < 10 then
      time.insert_in_place(s.isize() - 6, ".")
      unit = "ms"
    else
      time.insert_in_place(s.isize() - 9, ".")
      unit = "s "
    end
    try
      let i = time.find(".")?
      time.cut_in_place(i + 3)
    end
    padding = padding.substring(time.size().isize())
    let time_size = time.size()
    recover
      String(padding.size() + time_size + unit.size())
        .>append(padding)
        .>append(consume time)
        .>append(unit)
    end

class val CommonResponder is Responder
  """
  Logs HTTP requests in the common log format.
  """
  let _out: OutStream
  let _host: String

  new val create(out: OutStream) =>
    _out = out
    _host = try
      (let host, let service) = NetAddress.name()?
      recover String.>append(host).>push(':').>append(service) end
    else
      "jennet"
    end

  fun apply(res: Response, body: ByteArrays, ctx: Context box) =>
    ctx.session.send(res, body, ctx.request_id)
    match res.header("Connection")
    | let h: String if h.contains("close") => ctx.session.dispose()
    end

    let user = ctx.request.uri().user
    let referrer =
      match ctx.request.header("Referrer")
      | let s: String => s
      | None => ""
      end
    let ua =
      match ctx.request.header("User-Agent")
      | let s: String => s
      | None => ""
      end

    _out.writev(
      [ _host; " - "
        if user.size() > 0 then user else "-" end
        " ["
        try PosixDate(Time.seconds()).format("%d/%b/%Y:%H:%M:%S +0000")?
        else "ERROR"
        end
        "] \""; ctx.request.method().repr(); " "
        ctx.request.uri().path
        if ctx.request.uri().query.size() > 0
        then "?" + ctx.request.uri().query
        else ""
        end
        if ctx.request.uri().fragment.size() > 0
        then "#" + ctx.request.uri().fragment
        else ""
        end
        " "; ctx.request.version().string(); "\" "; res.status().string()
        " "; body.size().string(); " \""; referrer; "\" \""; ua; "\"\n"
      ])
