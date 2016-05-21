use "time"
use "net/http"
use "net"

// TODO common log

interface val Responder
  """
  Responds to the request and creates a log.
  """
  fun val apply(req: Payload, res: Payload, response_time: String)

class val DefaultResponder is Responder
  let _out: OutStream

  new val create(out: OutStream) =>
    _out = out

  fun val apply(req: Payload, res: Payload, response_time: String) =>
    let time = Date(Time.seconds()).format("%d/%b/%Y %H:%M:%S")
    let list = recover Array[String](13) end
    list.push("[")
    list.push("Pony") // TODO name
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
