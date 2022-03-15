use "net"
use "http_server"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)

    let server =
      Jennet(tcplauth, env.out)
        .> get("/", H)
        .> get("/:name", H)
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end

primitive H is RequestHandler
  fun apply(ctx: Context): Context iso^ =>
    let name = ctx.param("name")
    let body =
      "".join(
        [ "Hello"; if name != "" then " " + name else "" end; "!"
        ].values()).array()
    ctx.respond(StatusResponse(StatusOK), body)
    consume ctx
