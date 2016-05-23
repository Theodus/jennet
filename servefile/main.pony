use "net/http"
use ".."

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let rb = RouteBuilder(env.out)
      rb.serve_file(env.root as AmbientAuth, "/", "/index.html")
      Server(auth, ServerInfo(env.out), (consume rb).build(), DiscardLog
        where service = "8080", limit = USize(100), reversedns = auth)
    else
      env.out.print("unable to use network.")
    end
