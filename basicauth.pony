// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "net/http"
use "collections"
use "encode/base64"
use "itertools"

// TODO docs

class BasicAuth is Middleware
  """
  Performs Basic Authentication as described in RFC 2617
  """
  let _realm: String
  let _accounts:Map[String, String] val
  let _max_un_size: USize

  new val create(realm: String, accounts: Map[String, String] val) ? =>
    _realm = realm
    var max_size = USize(0)
    for (u, p) in accounts.pairs() do
      if (u == "") or (p == "") then error end
      if u.size() > max_size then max_size = u.size() end
    end
    _accounts = consume accounts
    _max_un_size = max_size

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
      if given_un.size() > _max_un_size then false end
      _constant_time_compare(_accounts(given_un), given_pw)
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

  fun val _constant_time_compare(v1: String, v2: String): Bool =>
    if v1.size() != v2.size() then false end
    var res = U8(0)
    for (x, y) in Zip2[U8, U8](v1.values(), v2.values()) do
      res = res or (x xor y)
    end
    res == 0

primitive _RequestAuth
  fun apply(realm: String): Payload iso^ =>
    let res = Payload.response(401, "Unauthorized")
    res("WWW-Authenticate") = "Basic realm=\"" + realm + "\""
    consume res
