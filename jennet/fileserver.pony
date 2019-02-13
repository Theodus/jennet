// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "files"
use "http"

class _FileServer is Handler
  let _auth: AmbientAuth
  let _filepath: String

  new val create(auth: AmbientAuth, filepath: String) =>
    _auth = auth
    _filepath = Path.abs(filepath)

  fun val apply(c: Context, req: Payload val): Context iso^ =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let res = try
      let r = Payload.response()
      with
        file = OpenFile(FilePath(_auth, _filepath, caps)?) as File
      do
        for line in file.lines() do
          r.add_chunk(consume line)
        end
      end
      consume r
    else
      _NotFoundRes()
    end
    c.respond(req, consume res)
    consume c

class _DirServer is Handler
  let _auth: AmbientAuth
  let _dir: String

  new val create(auth: AmbientAuth, dir: String) =>
    _auth = auth
    _dir = Path.abs(dir)

  fun val apply(c: Context, req: Payload val): Context iso^ =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let filepath = c.param("filepath")
    let res = try
      let r = Payload.response()
      let path = Path.join(_dir, filepath)
      with
        file = OpenFile(FilePath(_auth, path, caps)?) as File
      do
        for line in file.lines() do
          r.add_chunk(consume line)
        end
      end
      consume r
    else
      _NotFoundRes()
    end
    c.respond(req, consume res)
    consume c
