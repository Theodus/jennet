use "net/http"
use ".."

actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let rb = RouteBuilder(env.out)
    rb.get("/", H)
    let router = try
      (consume rb).build()
    else
      env.out.print("invalid routes.")
      return
    end
    Jennet(auth, env.out, consume router, "8080")


class H is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res.add_chunk("Hello!")
    c.respond(consume req, consume res)
    consume c
