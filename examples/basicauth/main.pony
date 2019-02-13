use "http"
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
      [as Middleware: BasicAuth("My Realm", consume users)]
    end

    let jennet = Jennet(auth, env.out, "8080")
    jennet.get(
      "/",
      {(c: Context, req: Payload val): Context iso^ =>
        let res = Payload.response()
        res.add_chunk("Hello!")
        c.respond(req, consume res)
        consume c
      },
      middleware
    )

    try
      (consume jennet).serve()?
    else
      env.out.print("invalid routes.")
    end
