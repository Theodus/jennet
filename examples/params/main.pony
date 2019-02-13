use "http"
use "../../jennet"

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
      (consume jennet).serve()?
    else
      env.out.print("invalid routes.")
    end

primitive H is Handler
  fun apply(c: Context, req: Payload val): Context iso^ =>
    let res = Payload.response()
    let name = c.param("name")
    res.add_chunk("Hello")
    if name != "" then
      res.add_chunk(" " + name)
    end
    res.add_chunk("!")
    c.respond(req, consume res)
    consume c
