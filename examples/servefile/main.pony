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

    let j = Jennet(auth, env.out, "8080")
    try
      j.serve_file(auth, "/", "index.html")?
    else
      env.out.print("invalid routes.")
      j.dispose()
    end
    let j' = consume val j
    try j'.serve()? else j'.dispose() end
