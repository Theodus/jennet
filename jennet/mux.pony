use "collections"
use "http"
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

  // TODO: no unwind
  fun val apply(method: String, path: String, params: Map[String, String])
    : _HandlerGroup ?
  =>
    let path' =
      if path(0)? != '/' then
        let p = recover String(path.size() + 1) end
        p.append("/")
        p.append(path)
        p
      else
        path
      end
    _methods(method)?(consume path', params) as _HandlerGroup
