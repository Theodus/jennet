use "files"
use "http_server"
use "valbytes"
use "debug"

use @pony_os_errno[I32]()

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
  Read a whole file into an `Array[U8] iso^` doing multiple calls to read in a loop.

  This is not optimally friendly to the whole runtime as it is hogging a scheduler thread doing blocking system calls.
  """
  fun apply(path: FilePath): ByteArrays ? =>
    Debug("Reading file " + path.path + " ...")
    with file = OpenFile(path) as File do
      file.clear_errno()
      let file_size = file.size()
      
      if file_size == -1 then
        let err_str = match file.errno()
        | FileError => "ERROR"
        | FilePermissionDenied => "Permission denied"
        | FileBadFileNumber => "Bad file number"
        | FileEOF => "EOF"
        | FileOK => "OK"
        | FileExists => "EXISTS"
        end
        Debug("ERROR: " + @pony_os_errno().string() + " " + err_str)
        error
      end
      Debug("file_size == " + if file_size == -1 then "-1" else file_size.string() end)
      var bs = ByteArrays
      var bytes_read = USize(0)
      while bytes_read < file_size do
        Debug("Reading " + (file_size - bytes_read).string() + " bytes from " + path.path)
        let data = file.read(file_size - bytes_read)
        bytes_read = bytes_read + data.size()
        bs = bs + consume data
      end
      bs
    end
    
