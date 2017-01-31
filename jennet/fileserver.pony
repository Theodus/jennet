// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

use "files"
use "net/http"

class _FileServer is Handler
  let _auth: AmbientAuth
  let _filepath: String

  new val create(auth: AmbientAuth, filepath: String) =>
    _auth = auth
    _filepath = filepath

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let res = try
      let r = Payload.response()
      let cwd = Path.cwd()
      let path = recover String(cwd.size() + _filepath.size()) end
      path.append(cwd)
      path.append(_filepath)
      with
        file = OpenFile(FilePath(_auth, consume path, caps)) as File
      do
        for line in file.lines() do
          r.add_chunk(line)
        end
      end
      consume r
    else
      _NotFoundRes()
    end
    c.respond(consume req, consume res)
    consume c

class _DirServer is Handler
  let _auth: AmbientAuth
  let _dir: String

  new val create(auth: AmbientAuth, dir: String) =>
    _auth = auth
    _dir = dir

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let caps = recover val FileCaps.>set(FileRead).>set(FileStat) end
    let filepath = c.param("filepath")
    let res = try
      let r = Payload.response()
      let cwd = Path.cwd()
      let path = recover String(cwd.size() + _dir.size() + filepath.size()) end
      path.append(cwd)
      path.append(_dir)
      path.append(filepath)
      with
        file = OpenFile(FilePath(_auth, consume path, caps)) as File
      do
        for line in file.lines() do
          r.add_chunk(line)
        end
      end
      consume r
    else
      _NotFoundRes()
    end
    c.respond(consume req, consume res)
    consume c
