use "collections"
use "http_server"
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
      {(ctx: Context): Context iso^ =>
        ctx.respond(StatusResponse(StatusOK), "Hello!".array())
        consume ctx
      }

    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let authenticator = BasicAuth("My Realm", consume users)

    let server =
      Jennet(auth, env.out)
        .> get("/", handler, [authenticator])
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
