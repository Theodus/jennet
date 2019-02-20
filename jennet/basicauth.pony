use "collections"
use "crypto"
use "encode/base64"
use "itertools"
use "http"

class BasicAuth is Middleware
  """
  Performs Basic Authentication as described in RFC 2617
  """
  let _realm: String
  let _accounts: Map[String, String] val
  let _max_un_size: USize

  new val create(realm: String, accounts: Map[String, String] val) =>
    _realm = realm
    var max_size = USize(0)
    for (u, p) in accounts.pairs() do
      if u.size() > max_size then max_size = u.size() end
    end
    _accounts = consume accounts
    _max_un_size = max_size

  fun val apply(c: Context, req: Payload val): (Context iso^, Payload val) ? =>
    let authorized = try
      let auth = req("Authorization")?
      let basic_scheme = "Basic "
      if not auth.at(basic_scheme) then error end
      let decoded = Base64.decode[String iso](auth.substring(basic_scheme.size().isize()))?
      let creds = decoded.split(":")
      if creds.size() != 2 then error end
      let given_un = creds(0)?
      let given_pw = creds(1)?
      if given_un.size() > _max_un_size then false end
      ConstantTimeCompare(_accounts(given_un)?, given_pw)
    else
      false
    end
    if authorized then
      (consume c, req)
    else
      c.respond(consume req, _RequestAuth(_realm))
      error
    end

  fun val after(c: Context): Context iso^ =>
    consume c

primitive _RequestAuth
  fun apply(realm: String): Payload iso^ =>
    let res = Payload.response(StatusUnauthorized)
    res("WWW-Authenticate") = "Basic realm=\"" + realm + "\""
    consume res
