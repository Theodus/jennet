// Copyright 2016 Theodore Butler. All rights reserved.
// Use of this source code is governed by an MIT style
// license that can be found in the LICENSE file.

class val _Route
  let method: String
  let path: String
  let hg: _HandlerGroup

  new val create(method': String, path': String, hg': _HandlerGroup)
  =>
    method = method'
    path = path'
    hg = hg'
