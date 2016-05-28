// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "time"
use "net/http"

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
    let esc = "\x1b"
    list.push(esc)
    list.push("[1;")
    let status = res.status
    list.push(
      if (status >= 200) and (status < 300) then
        "32m"
      elseif (status >= 300) and (status < 400) then
        "37m"
      elseif (status >= 400) and (status < 500) then
        "33m"
      else
        "31m"
      end)
    list.push(status.string())
    list.push(esc)
    list.push("[0m| ")
    list.push(response_time)
    list.push("| ")
    list.push(req.method)
    list.push(" ")
    list.push(req.url.path)
    list.push("\n")
    _out.writev(consume list)
    (consume req).respond(consume res)

class CommonResponder is Responder
  let _out: OutStream

  new val create(out: OutStream) =>
    _out = out

  fun val apply(req: Payload, res: Payload, response_time: String, host: String)
  =>
    let list = recover Array[String](24) end
    list.push(host)
    list.push(" - ")
    list.push(_entry(req.url.user))
    let time = Date(Time.seconds()).format("%d/%b/%Y:%H:%M:%S +0000")
    list.push(" [")
    list.push(time)
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

  fun _entry(s: String): String =>
    if s.size() > 0 then s else "-" end
