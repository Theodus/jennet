use "files"
use "http"

class _FileServer is Handler
  let _filepath: FilePath

  new val create(filepath: FilePath) =>
    _filepath = filepath

  fun val apply(c: Context, req: Payload val): Context iso^ =>
    let res =
      try
        let r = Payload.response()
        with file = OpenFile(_filepath) as File do
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
  let _dir: FilePath

  new val create(dir: FilePath) =>
    _dir = dir

  fun val apply(c: Context, req: Payload val): Context iso^ =>
    let filepath = c.param("filepath")
    let res =
      try
        let r = Payload.response()
        with file = OpenFile(_dir.join(filepath)?) as File do
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
