// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "net"
use "net/http"
use "term"
use "time"

interface val Responder
  """
  Responds to the request and creates a log.
  """
  fun apply(req: Payload, res: Payload, response_time: U64)

class val DefaultResponder is Responder
  let _out: OutStream
  let _host: String

  new val create(out: OutStream) =>
    _out = out
    _host = try
      (let host, let service) = IPAddress.name()
      recover String.>append(host).>push(':').>append(service) end
    else
      "Jennet" // TODO get IP from server
    end

  fun apply(req: Payload, res: Payload, response_time: U64) =>
    let time = Date(Time.seconds()).format("%d/%b/%Y %H:%M:%S")
    let status = res.status
    _out.writev(recover
      Array[String](15)
        .>push("[")
        .>push(_host)
        .>push("] ")
        .>push(time)
        .>push(" |")
        .>push(
          if (status >= 200) and (status < 300) then
            ANSI.bright_green()
          elseif (status >= 300) and (status < 400) then
            ANSI.bright_blue()
          elseif (status >= 400) and (status < 500) then
            ANSI.bright_yellow()
          else
            ANSI.bright_red()
          end)
        .>push(status.string())
        .>push(ANSI.reset())
        .>push("| ")
        .>push(_format_time(response_time))
        .>push(" | ")
        .>push(req.method)
        .>push(" ")
        .>push(req.url.path)
        .>push("\n")
    end)
    (consume req).respond(consume res)

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
      let i = time.find(".")
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
      (let host, let service) = IPAddress.name()
      recover String.>append(host).>push(':').>append(service) end
    else
      "jennet"
    end

  fun apply(req: Payload, res: Payload, response_time: U64) =>
    let user = req.url.user
    _out.writev(recover
      let list = Array[String](24)
        .>push(_host)
        .>push(" - ")
        .>push(if user.size() > 0 then user else "-" end)
        .>push(" [")
        .>push(Date(Time.seconds()).format("%d/%b/%Y:%H:%M:%S +0000"))
        .>push("] \"")
        .>push(req.method)
        .>push(" ")
        .>push(req.url.path)
      if req.url.query.size() > 0 then
        list.push("?")
        list.push(req.url.query)
      end
      if req.url.fragment.size() > 0 then
        list.push("#")
        list.push(req.url.fragment)
      end
      list
        .>push(" ")
        .>push(req.proto)
        .>push("\" ")
        .>push(res.status.string())
        .>push(" ")
        .>push(res.body_size().string())
        .>push(" \"")
      try list.push(req("Referrer")) end
      list.push("\" \"")
      try list.push(req("User-Agent")) end
      list.>push("\"\n")  
    end)
    (consume req).respond(consume res)
