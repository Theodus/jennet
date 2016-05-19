use "net"

class iso _RouterNotify
  let _router: Router
  let _logger: Logger

  new iso create(router: Router, logger: Logger) =>
    _router = router
    _logger = logger

  fun ref listening(router: Router ref) =>
    try
      (let host, let service) = router.local_address().name()
      _logger.print("Listening on " + host + ":" + service)
    else
      _logger.print("Couldn't get local address.")
      _router.dispose()
    end

  fun ref not_listening(router: Router ref) =>
    _logger.print("Failed to listen.")

  fun ref closed(router: Router ref) =>
    _logger.print("Shutdown.")
