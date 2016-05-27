use "net/http"
use "net"

// TODO docs
// TODO get hostname to logger

class Jennet
  let _server: Server
  let _out: OutStream

  new create(
    auth: (AmbientAuth val | NetAuth val),
    out: OutStream, router: Router, service: String)
  =>
    _server = Server(auth, _ServerInfo(out), router, DiscardLog
      where service = service, reversedns = auth)
    _out = out
