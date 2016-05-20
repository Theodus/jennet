use "net/http"
use ".."

use "debug"

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let router = Router
      let mw = recover val
        let ma = Array[Middleware](1)
        ma.push(MW)
        consume ma
      end
      router.get("/", object
        fun val apply(c: Context, req: Payload): Context iso^ =>
          let res = Payload.response()
          res.add_chunk("yup.")
          (consume req).respond(consume res)
          consume c
      end, mw)
      router.start()
      Server(auth, Info(env), consume router, CommonLog(env.out)
        where service = "8080", limit = USize(100), reversedns = auth)
    else
      env.out.print("unable to use network.")
    end

class MW is Middleware
  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) =>
    Debug.out("--- yup. ---")
    (consume c, consume req)
  fun val after(c: Context): Context iso^ =>
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
