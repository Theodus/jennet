use "net"
use "files"
use "http_server"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)
    let fileauth: FileAuth = FileAuth(env.root)

    let server =
      Jennet(tcplauth, env.out)
        .> serve_file(fileauth, "/", "index.html")
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
