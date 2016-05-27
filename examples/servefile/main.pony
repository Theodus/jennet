use "net/http"
use "../.."

actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let jennet = Jennet(auth, env.out, "8080")
    jennet.serve_file(auth, "/", "/index.html")
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
      return
    end
