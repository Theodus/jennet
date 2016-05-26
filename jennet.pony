use "net/http"

// TODO docs
// TODO get hostname to logger

class Jennet
  let _server: Server

  new create(env: Env, router: Router, service: String) ? =>
    let auth = env.root as AmbientAuth
    _server = Server(auth, _ServerInfo(env.out), router, DiscardLog
      where service = service, reversedns = auth)
