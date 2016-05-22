use "net/http"
use "collections"
use "encode/base64"

class BasicAuth is Middleware
  """
  Performs Basic Authentication as described in RFC 2617
  """
  let _realm: String
  let _accounts:Map[String, String] val

  new val create(realm: String, accounts: Map[String, String] iso^) ? =>
    _realm = realm
    for (u, p) in accounts.pairs() do
      if (u == "") or (p == "") then error end
    end
    _accounts = consume accounts

  fun val apply(c: Context, req: Payload): (Context iso^, Payload iso^) ? =>
    let authorized = try
      let auth = req("Authorization")
      let basic_scheme = "Basic "
      if not auth.at(basic_scheme) then error end
      let decoded = Base64.decode[String iso](auth.substring(basic_scheme.size().isize()))
      let creds = decoded.split(":")
      if creds.size() != 2 then error end
      let given_un = creds(0)
      let given_pw = creds(1)
      // TODO constant time comparison to protect from timing attacks
      _accounts(given_un) == given_pw
    else
      false
    end
    if authorized then
      (consume c, consume req)
    else
      c.respond(consume req, _RequestAuth(_realm))
      error
    end

  fun val after(c: Context): Context iso^ =>
    consume c

primitive _RequestAuth
  fun apply(realm: String): Payload iso^ =>
    let res = Payload.response(401, "Unauthorized")
    res("WWW-Authenticate") = "Basic realm=\"" + realm + "\""
    consume res
