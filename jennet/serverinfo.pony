use "http/server"
use "promises"

class _ServerInfo is ServerNotify
    let _out: OutStream
    let _responder: Responder

    new iso create(out: OutStream, responder: Responder) =>
      _out = out
      _responder = responder

    fun ref listening(server: Server ref) =>
      try
        (let host, let service) = server.local_address().name()?
        _out.print("Listening on " + host + ":" + service)
      else
        _out.print("Couldn't get local address.")
        server.dispose()
      end

    fun ref not_listening(server: Server ref) =>
      _out.print("Failed to listen.")

    fun ref closed(server: Server ref) =>
      _out.print("Shutdown.")
