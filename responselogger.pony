use "time"
use "net/http"
use "net"

// TODO docs
// TODO optional colors!

interface val ResponseLogger
  fun val apply(method: String, path: String, proto: String, status: U16,
    body_size: USize, response_time: String)

class val _DefaultLogger is ResponseLogger
  let _out: OutStream

  new val create(out: OutStream) =>
    _out = out

  fun val apply(method: String, path: String, proto: String, status: U16,
    body_size: USize, response_time: String)
  =>
    let time = Date(Time.seconds()).format("%d/%b/%Y %H:%M:%S")
    let list = recover Array[String](13) end
    list.push("[")
    list.push("Pony") // TODO name
    list.push("] ")
    list.push(time)
    list.push(" |")
    list.push(status.string())
    list.push("| ")
    list.push(response_time)
    list.push(" |")
    list.push(method)
    list.push(" ")
    list.push(path)
    list.push("\n")
    _out.writev(consume list)
