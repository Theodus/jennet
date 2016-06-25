use "net/http"
use "../../jennet"
use "collections"

actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let middleware = recover val
      let mw = Array[Middleware](1)
      mw.push(BasicAuth("My Realm", consume users))
    end
    let jennet = Jennet(auth, env.out, "8080")
    jennet.get("/", H, middleware)
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
    end

class H is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res.add_chunk("Hello!")
    c.respond(consume req, consume res)
    consume c
