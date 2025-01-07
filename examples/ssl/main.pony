use "net"
use "files"
use "net_ssl"
use "http_server"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)
    let fileauth: FileAuth = FileAuth(env.root)

    try
      let sslctx: SSLContext =
        try
          recover
            SSLContext
              .>set_cert(
                FilePath(fileauth, "cert.pem"),
                FilePath(fileauth, "key.pem")
              )?
          end
        else
          env.err.print("Unable to configure SSL")
          error
        end

      let server =
        Jennet(tcplauth, env.out)
          .> get("/", H)
          .> sslctx(sslctx)
          .serve(ServerConfig(where port' = "8443"))

      if server is None then
        env.err.print("bad routes!")
        error
      end
    else
      env.err.print("Server unable to start")
    end

primitive H is RequestHandler
  fun apply(ctx: Context): Context iso^ =>
    let body = "Hello".array()
    ctx.respond(
      StatusResponse(
        StatusOK,
        [("Content-Length", body.size().string())]
      ),
      body
    )
    consume ctx
