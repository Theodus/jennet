use "files"
use "http/server"
use "valbytes"

class _FileServer is RequestHandler
  let _filepath: FilePath

  new val create(filepath: FilePath) =>
    _filepath = filepath

  fun val apply(ctx: Context): Context iso^ =>
    try
      var bs = ByteArrays
      with file = OpenFile(_filepath) as File do
        for line in file.lines() do
          bs = bs + consume line
        end
      end
      ctx.respond(StatusResponse(StatusOK), bs)
    else
      ctx.respond(StatusResponse(StatusNotFound))
    end
    consume ctx

class _DirServer is RequestHandler
  let _dir: FilePath
  let _response_builder: ResponseBuilder = Responses.builder()

  new val create(dir: FilePath) =>
    _dir = dir

  fun val apply(ctx: Context): Context iso^ =>
    let filepath = ctx.param("filepath")
    try
      var bs = ByteArrays
      with file = OpenFile(_dir.join(filepath)?) as File do
        for line in file.lines() do
          bs = bs + consume line
        end
      end
      ctx.respond(StatusResponse(StatusOK), bs)
    else
      ctx.respond(StatusResponse(StatusNotFound))
    end
    consume ctx
