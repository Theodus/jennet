use "http"
use "promises"

class _ServerInfo is ServerNotify
    let _out: OutStream
    let _responder: Responder

    new iso create(out: OutStream, responder: Responder) =>
      _out = out
      _responder = responder

    fun ref listening(server: HTTPServer ref) =>
      try
        (let host, let service) = server.local_address().name()?
        _out.print("Listening on " + host + ":" + service)
      else
        _out.print("Couldn't get local address.")
        server.dispose()
      end

    fun ref not_listening(server: HTTPServer ref) =>
      _out.print("Failed to listen.")

    fun ref closed(server: HTTPServer ref) =>
      _out.print("Shutdown.")
