use "net/http"
use ".."

actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let rb = RouteBuilder(env.out)
    rb.serve_file(auth, "/", "/index.html")
    let router = try
      (consume rb).build()
    else
      env.out.print("invalid routes.")
      return
    end
    Jennet(auth, env.out, consume router, "8080")
