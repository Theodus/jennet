use "net/http"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end

    let jennet = Jennet(auth, env.out, "8080")
    // a request to /fs/index.html would return /static/index.html
    jennet.serve_dir(auth, "/fs/*filepath", "/static/")
    
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
    end
