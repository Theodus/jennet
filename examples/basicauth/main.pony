use "collections"
use "http"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let auth =
      try
        env.root as AmbientAuth
      else
        env.out.print("unable to use network.")
        return
      end

    let handler =
      {(c: Context, req: Payload val): Context iso^ =>
        let res = Payload.response()
        res.add_chunk("Hello!")
        c.respond(req, consume res)
        consume c
      }

    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let authenticator = BasicAuth("My Realm", consume users)

    let j =
      Jennet(auth, env.out, "8080")
        .> get("/", handler, [authenticator])

    let j' = consume val j
    try j'.serve()? else j'.dispose() end
