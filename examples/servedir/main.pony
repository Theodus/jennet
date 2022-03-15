use "net"
use "http_server"
use "files"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)
    let fileauth: FileAuth = FileAuth(env.root)

    let server =
        Jennet(tcplauth, env.out)
          // a request to /fs/index.html would return ./static/index.html
          .> serve_dir(fileauth, "/fs/*filepath", "static/")
          .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
