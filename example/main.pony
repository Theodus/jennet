use "net/http"
use ".."

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let rb = RouteBuilder
      let mw = recover val
        let ma = Array[Middleware](2)
        ma.push(MW(env, 0))
        ma.push(MW(env, 1))
        ma.push(MW(env, 2))
        ma.push(MW(env, 3))
        ma.push(MW(env, 4))
        ma.push(MW(env, 5))
        ma.push(MW(env, 6))
        ma.push(MW(env, 7))
        ma.push(MW(env, 8))
        ma.push(MW(env, 9))
        consume ma
      end
      rb.get("/", H(env), mw)
      Server(auth, Info(env), (consume rb).build(), DiscardLog
        where service = "8080", limit = USize(100), reversedns = auth)
    else
      env.out.print("unable to use network.")
    end

class MW is Middleware
  let _env: Env
  let _id: USize

  new val create(env: Env, id: USize) =>
    _env = env
    _id = id

  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) =>
    let msg = recover String(23) end
    msg.append("--- Middleware ")
    msg.append(_id.string())
    msg.append(": apply")
    _env.out.print(consume msg)
    (consume c, consume req)

  fun val after(c: Context): Context iso^ =>
    let msg = recover String(23) end
    msg.append("--- Middleware ")
    msg.append(_id.string())
    msg.append(": after")
    _env.out.print(consume msg)
    consume c

class H is Handler
  let _env: Env

  new val create(env: Env) =>
    _env = env

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res.add_chunk("yup.")
    _env.out.print("--- Handler")
    (consume req).respond(consume res)
    consume c

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
