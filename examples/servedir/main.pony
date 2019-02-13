use "http"
use "../../jennet"
use "files"

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
    let dir = Path.cwd()
    jennet.serve_dir(auth, "/fs/*filepath", dir)

    try
      (consume jennet).serve()?
    else
      env.out.print("invalid routes.")
    end
