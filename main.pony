use "net/http"
use "options"

actor Main
  """
    options for httpserver:
    --port, -p
    --logger, -l [discard, contents, common]
  """
  var _port: U32 = 50000
  var _logger: Logger = DiscardLog
  let _env: Env

  new create(env: Env) =>
    _env = env

    // try
    //   arguments()
    // end

    let service = try env.args(1) else "50000" end
    let limit = try env.args(2).usize() else 100 end

    // let logger = CommonLog(env.out)
    let logger = DiscardLog
    // let logger = ContentsLog(env.out)
    // let logger = DiscardLog

    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network")
      return
    end

    // Server(auth, Info(env), HandleDot(env), logger
    //   where service=service, limit=limit, reversedns=auth
    // )
    Server(auth, Info(env), Handle, logger
      where service=service, limit=limit, reversedns=auth
    )

class Info
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref listening(server: Server ref) =>
    try
      (let host, let service) = server.local_address().name()
      _env.out.print("Listening on " + host + ":" + service)
    else
      _env.out.print("Couldn't get local address.")
      server.dispose()
    end

  fun ref not_listening(server: Server ref) =>
    _env.out.print("Failed to listen.")

  fun ref closed(server: Server ref) =>
    _env.out.print("Shutdown.")

primitive Handle
  fun val apply(request: Payload) =>
    let response = Payload.response()
    response.add_chunk("You asked for ")
    response.add_chunk(request.url.path)

    if request.url.query.size() > 0 then
      response.add_chunk("?")
      response.add_chunk(request.url.query)
    end

    if request.url.fragment.size() > 0 then
      response.add_chunk("#")
      response.add_chunk(request.url.fragment)
    end

    (consume request).respond(consume response)

class HandleDot
  let _env: Env

  new val create(env: Env) =>
    _env = env

  fun val apply(request: Payload) =>
    let response = Payload.response()
    response.add_chunk("Dot: You asked for ")
    response.add_chunk(request.url.path)

    if request.url.query.size() > 0 then
      response.add_chunk("?")
      response.add_chunk(request.url.query)
    end

    if request.url.fragment.size() > 0 then
      response.add_chunk("#")
      response.add_chunk(request.url.fragment)
    end

    (consume request).respond(consume response)    

    _env.out.write(".")