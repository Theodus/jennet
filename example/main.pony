use "net/http"
use ".."

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let rb = RouteBuilder(env.out)
      rb.get("/", H)
      Jennet(env, (consume rb).build(), "8080")
    else
      env.out.print("unable to use network.")
    end

class H is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res.add_chunk("Hello!")
    c.respond(consume req, consume res)
    consume c
