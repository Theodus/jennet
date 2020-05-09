# jennet [![CircleCI](https://circleci.com/gh/Theodus/jennet.svg?style=svg)](https://circleci.com/gh/Theodus/jennet)
A simple HTTP web framework written in Pony

pony-stable: `{ "type": "github", "repo": "theodus/jennet" }`

## Features
- **Context:** Store data that can be used by the request handler as well as any middleware.

- **Middleware Chaining:** Easily add multiple middlewares to the route that can execute functions both before and after the request handler.

- **Explicit Route Matches:** A request can only match exactly one or no route so that there are no unintended matches.

- **Route Parameters:** Allow the router to parse the incoming URL path for you by specifying a route parameter. The router will then store a dynamic value in the context.

- **File Server:** Easily serve static files and set custom NotFound handlers.

## Usage

### Named Parameters

```pony
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let auth =
      try
        env.root as AmbientAuth
      else
        env.out.print("unable to use network.")
        return
      end

    let server =
      Jennet(auth, env.out)
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
    ctx.respond(StatusResponse(StatusOK), body)
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
use "collections"
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let auth =
      try
        env.root as AmbientAuth
      else
        env.out.print("unable to use network.")
        return
      end

    let handler =
      {(ctx: Context, req: Request): Context iso^ =>
        ctx.respond(StatusResponse(StatusOK), "Hello!".array())
        consume ctx
      }

    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let authenticator = BasicAuth("My Realm", consume users)

    let server =
      Jennet(auth, env.out)
        .> get("/", handler, [authenticator])
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
```

This example uses Basic Authentication (RFC 2617) with the included BasicAuth middleware.

### Serving Static Files

```pony
use "http_server"
use "jennet"

actor Main
  new create(env: Env) =>
    let auth =
      try
        env.root as AmbientAuth
      else
        env.out.print("unable to use network.")
        return
      end

    let server =
      try
        Jennet(auth, env.out)
          .> serve_file(auth, "/", "index.html")?
          .serve(ServerConfig(where port' = "8080"))
      else
        env.out.print("bad file path!")
        return
      end

    if server is None then env.out.print("bad routes!") end
```

### Serving Static Directory

```pony
use "http_server"
use "files"
use "jennet"

actor Main
  new create(env: Env) =>
    let auth =
      try
        env.root as AmbientAuth
      else
        env.out.print("unable to use network.")
        return
      end

    let server =
      try
        Jennet(auth, env.out)
          // a request to /fs/index.html would return ./static/index.html
          .> serve_dir(auth, "/fs/*filepath", "static/")?
          .serve(ServerConfig(where port' = "8080"))
      else
        env.out.print("bad file path!")
        return
      end

    if server is None then env.out.print("bad routes!") end
```
