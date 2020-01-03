use "http"
use "files"
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
      // a request to /fs/index.html would return ./static/index.html
      j.serve_dir(auth, "/fs/*filepath", "static/")?
    else
      env.out.print("Invalid routes!")
      j.dispose()
    end
    let j' = consume val j
    try j'.serve()? else j'.dispose() end
