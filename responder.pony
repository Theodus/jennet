// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "time"
use "net/http"
use "term"

interface val Responder
  """
  Responds to the request and creates a log.
  """
  fun val apply(req: Payload, res: Payload, response_time: String, host: String)

class DefaultResponder is Responder
  let _out: OutStream

  new val create(out: OutStream) =>
    _out = out

  fun val apply(req: Payload, res: Payload, response_time: String, host: String)
  =>
    let time = Date(Time.seconds()).format("%d/%b/%Y %H:%M:%S")
    let list = recover Array[String](17) end
    list.push("[")
    list.push(host)
    list.push("] ")
    list.push(time)
    list.push(" |")
    let status = res.status
    list.push(
      if (status >= 200) and (status < 300) then
        ANSI.bright_green()
      elseif (status >= 300) and (status < 400) then
        ANSI.bright_blue()
      elseif (status >= 400) and (status < 500) then
        ANSI.bright_yellow()
      else
        ANSI.bright_red()
      end)
    list.push(status.string())
    list.push(ANSI.reset())
    list.push("| ")
    list.push(response_time)
    list.push(" | ")
    list.push(req.method)
    list.push(" ")
    list.push(req.url.path)
    list.push("\n")
    _out.writev(consume list)
    (consume req).respond(consume res)

class CommonResponder is Responder
  """
  Logs HTTP requests in the common log format.
  """
  let _out: OutStream

  new val create(out: OutStream) =>
    _out = out

  fun val apply(req: Payload, res: Payload, response_time: String, host: String)
  =>
    let list = recover Array[String](24) end
    list.push(host)
    list.push(" - ")
    let user = req.url.user
    list.push(if user.size() > 0 then user else "-" end)
    list.push(" [")
    list.push(Date(Time.seconds()).format("%d/%b/%Y:%H:%M:%S +0000"))
    list.push("] \"")
    list.push(req.method)
    list.push(" ")
    list.push(req.url.path)
    if req.url.query.size() > 0 then
      list.push("?")
      list.push(req.url.query)
    end
    if req.url.fragment.size() > 0 then
      list.push("#")
      list.push(req.url.fragment)
    end
    list.push(" ")
    list.push(req.proto)
    list.push("\" ")
    list.push(res.status.string())
    list.push(" ")
    list.push(res.body_size().string())
    list.push(" \"")
    try list.push(req("Referrer")) end
    list.push("\" \"")
    try list.push(req("User-Agent")) end
    list.push("\"\n")
    _out.writev(consume list)
    (consume req).respond(consume res)
