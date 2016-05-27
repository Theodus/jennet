use "net/http"
use "files"

class _FileServer is Handler
  let _auth: AmbientAuth
  let _filepath: String

  new val create(auth: AmbientAuth, filepath: String) =>
    _auth = auth
    _filepath = filepath

  fun val apply(c: Context, req: Payload): Context iso^ =>
    let caps = recover val FileCaps.set(FileRead).set(FileStat) end
    let res = try
      let r = Payload.response()
      with
        file = OpenFile(FilePath(_auth, Path.cwd() + _filepath, caps)) as File
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
