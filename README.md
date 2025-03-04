# jennet
[![ponyc-release](https://github.com/Theodus/jennet/actions/workflows/ponyc-release.yml/badge.svg)](https://github.com/Theodus/jennet/actions/workflows/ponyc-release.yml)

A simple HTTP web framework written in Pony

## Features
- **Context:** Store data that can be used by the request handler as well as any middleware.

- **Middleware Chaining:** Easily add multiple middlewares to the route that can execute functions both before and after the request handler.

- **Explicit Route Matches:** A request can only match exactly one or no route so that there are no unintended matches.

- **Route Parameters:** Allow the router to parse the incoming URL path for you by specifying a route parameter. The router will then store a dynamic value in the context.

- **File Server:** Easily serve static files and set custom NotFound handlers.

## Usage

### Installation
- Install [corral](https://github.com/ponylang/corral)
- `corral add github.com/theodus/jennet.git`
- `corral fetch` to fetch your dependencies
- `use "jennet"` to include this package
- `corral run -- ponyc` to compile your application

### Named Parameters

```pony
use "net"
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)

    let server =
      Jennet(tcplauth, env.out)
        .> get("/", H)
        .> get("/:name", H)
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end

primitive H is RequestHandler
  fun apply(ctx: Context): Context iso^ =>
    let name = ctx.param("name")
    let body =
      "".join(
        [ "Hello"; if name != "" then " " + name else "" end; "!"
        ].values()).array()
    ctx.respond(
      StatusResponse(
        StatusOK,
        [("Content-Length", body.size().string())]
      ),
      body
    )
    consume ctx
```

As you can see, `:name` is a named parameter. The values are accessible via the Context. In this example :name can be retrieved by `c.param("name")`.

Named parameters only match a single path segment:
```
Path: /user/:username

 /user/jim                 match
 /user/greg                match
 /user/greg/info           no match
 /user/                    no match
```

There are also catch-all parameters that may be used at the end of a path:
```
Pattern: /src/*filepath

 /src/                       match
 /src/somefile.html          match
 /src/subdir/somefile.pony   match
```

The router uses a compact prefix tree algorithm (or [Radix Tree](https://en.wikipedia.org/wiki/Radix_tree)) since URL paths have a hierarchical structure and only make use of a limited set of characters (byte values). It is very likely that there are a lot of common prefixes, which allows us to easily match incoming URL paths.

see also: [julienschmidt/httprouter](https://github.com/julienschmidt/httprouter)

### Using Middleware

```pony
use "net"
use "collections"
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)

    let handler =
      {(ctx: Context, req: Request): Context iso^ =>
        ctx.respond(
          StatusResponse(
            StatusOK,
            [("Content-Length", "6")]
          ),
          "Hello!".array()
        )
        consume ctx
      }

    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let authenticator = BasicAuth("My Realm", consume users)

    let server =
      Jennet(tcplauth, env.out)
        .> get("/", handler, [authenticator])
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
```

This example uses Basic Authentication (RFC 2617) with the included BasicAuth middleware.

### Serving Static Files

```pony
use "net"
use "files"
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)
    let fileauth: FileAuth = FileAuth(env.root)

    let server =
      Jennet(tcplauth, env.out)
        .> serve_file(fileauth, "/", "index.html")
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
```

### Serving Static Directory

```pony
use "net"
use "http_server"
use "files"
use "jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)
    let fileauth: FileAuth = FileAuth(env.root)

    let server =
      Jennet(tcplauth, env.out)
        // a request to /fs/index.html would return ./static/index.html
        .> serve_dir(fileauth, "/fs/*filepath", "static/")
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
```

### Serving over SSL

Refer to the [SSLContext](https://ponylang.github.io/net_ssl/net_ssl-SSLContext/) documentation in [net_ssl](https://ponylang.github.io/net_ssl/) for SSL / TLS configuration.

```pony
use "net"
use "files"
use "net_ssl"
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)
    let fileauth: FileAuth = FileAuth(env.root)

    try
      let sslctx: SSLContext =
        try
          recover
            SSLContext
              .> set_cert(
                FilePath(fileauth, "cert.pem"),
                FilePath(fileauth, "key.pem")
              )?
          end
        else
          env.err.print("Unable to configure SSL")
          error
        end

      let server =
        Jennet(tcplauth, env.out)
          .> get("/", H)
          .> sslctx(sslctx)
          .serve(ServerConfig(where port' = "8443"))

      if server is None then
        env.err.print("bad routes!")
        error
      end
    else
      env.err.print("Server unable to start")
    end

primitive H is RequestHandler
  fun apply(ctx: Context): Context iso^ =>
    let body = "Hello".array()
    ctx.respond(
      StatusResponse(
        StatusOK,
        [("Content-Length", body.size().string())]
      ),
      body
    )
    consume ctx
```
