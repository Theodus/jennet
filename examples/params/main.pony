use "net/http"
use "../.."

actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let jennet = Jennet(auth, env.out, "8080")
    jennet.get("/", H)
    jennet.get("/:name", H)
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
      return
    end

class H is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    let name = try c.param("name") as String else None end
    res.add_chunk("Hello")
    match name
    | let s: String => res.add_chunk(" " + s)
    end
    res.add_chunk("!")
    c.respond(consume req, consume res)
    consume c
