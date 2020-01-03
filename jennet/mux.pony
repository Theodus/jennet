use "collections"
use "http"
use "itertools"
use "radix"

// TODO weight optimization
// TODO path auto-correction

class val _Mux
  let _methods: Map[String, Radix[_HandlerGroup]]

  new trn create(routes: Array[_Route] val) ? =>
    _methods = Map[String, Radix[_HandlerGroup]]
    for r in routes.values() do
      let method = r.method
      let hg = _HandlerGroup(r.hg.handler, r.hg.middlewares)
      if not _methods.contains(method) then
        _methods(method) = Radix[_HandlerGroup]
      end
      _methods(method)?(r.path.clone())? = hg
    end

  fun val apply(method: String, path: String, params: Map[String, String])
    : (_HandlerGroup | None)
  =>
    try
      let path' =
        if (path.size() == 0) or (path(0)? != '/')
        then recover String(path.size() + 1) .> append("/") .> append(path) end
        else consume path
        end

      match _methods(method)?(consume path', params)
      | let hg: _HandlerGroup => hg
      end
    end

  fun debug(): String iso^ =>
    "\n".join(Iter[(String, Radix[_HandlerGroup] box)](_methods.pairs())
      .map[String]({(p) => p._1 + "\n" + p._2.string() }))
