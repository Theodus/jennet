use "http"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let auth =
      try
        env.root as AmbientAuth
      else
        env.out.print("unable to use network.")
        return
      end

    let server =
      try
        Jennet(auth, env.out)
          .> serve_file(auth, "/", "index.html")?
          .serve(ServerConfig(where port' = "8080"))
      else
        env.out.print("bad file path!")
        return
      end

    if server is None then env.out.print("bad routes!") end
