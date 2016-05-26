use "net/http"
use ".."

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let rb = RouteBuilder(env.out)
      rb.serve_file(env.root as AmbientAuth, "/", "/index.html")
      Jennet(env, (consume rb).build(), "8080")
    else
      env.out.print("unable to use network.")
    end
