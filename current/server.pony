use "net/http"

actor Main
  new create(env: Env) =>
    let service = "8080"
    let limit = USize(100)

    try
      let auth = env.root as AmbientAuth
      Server(auth, Info(env), Handle, CommonLog(env.out)
        where service = service, limit = limit, reversedns = auth)
    else
      env.out.print("unable to use network")
    end

class iso Info
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref listening(server: Server ref) =>
    try
      (let host, let service) = server.local_address().name()
      _env.out.print("Listening on " + host + ":" + service)
    else
      _env.out.print("Couldn't get local address.")
      server.dispose()
    end

  fun ref not_listening(server: Server ref) =>
    _env.out.print("Failed to listen.")

  fun ref closed(server: Server ref) =>
    _env.out.print("Shutdown.")

primitive Handle
  fun val apply(req: Payload) =>
    let res = Payload.response()
    res.add_chunk("You asked for ")
    res.add_chunk(req.url.path)
    (consume req).respond(consume res)
