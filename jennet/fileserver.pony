use "files"
use "http_server"
use "valbytes"


class _FileServer is RequestHandler
  let _filepath: FilePath

  new val create(filepath: FilePath) =>
    _filepath = filepath

  fun val apply(ctx: Context): Context iso^ =>
    try
      let data = _ReadFile(_filepath)?
      ctx.respond(
        StatusResponse(
          StatusOK,
          [("Content-Length", data.size().string())]
        ),
        consume data
      )
    else
      ctx.respond(StatusResponse(StatusNotFound))
    end
    consume ctx

class _DirServer is RequestHandler
  let _dir: FilePath

  new val create(dir: FilePath) =>
    _dir = dir

  fun val apply(ctx: Context): Context iso^ =>
    let filepath = ctx.param("filepath")
    try
      let data = _ReadFile(_dir.join(filepath)?)?
      ctx.respond(
        StatusResponse(
          StatusOK,
          [("Content-Length", data.size().string())]
        ),
        consume data
      )
    else
      ctx.respond(StatusResponse(StatusNotFound))
    end
    consume ctx

primitive _ReadFile
  """
  Read a whole file into a `ByteArrays` instance doing multiple calls to read in a loop.

  This is not optimally friendly to the whole runtime as it is hogging a scheduler thread doing blocking system calls.
  """
  fun apply(path: FilePath): ByteArrays ? =>
    with file = OpenFile(path) as File do
      let file_size = file.size()
      if file_size == -1 then
        error
      end
      var bs = ByteArrays
      var bytes_read = USize(0)
      while bytes_read < file_size do
        let data = file.read(file_size - bytes_read)
        bytes_read = bytes_read + data.size()
        bs = bs + consume data
      end
      bs
    end
    
