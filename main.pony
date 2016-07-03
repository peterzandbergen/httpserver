use "net/http"
use "options"

actor Main
  """
    options for httpserver:
    --port, -p => U32
    --logger, [discard, contents, common]
    --limit, -l limit for ??? U32
  """
  var _port: U32 = 50000
  var _logger: Logger = DiscardLog
  var _limit: USize = 100
  let _env: Env

  new create(env: Env) =>
    _env = env

    try
      arguments()
    else
      return
    end


    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network")
      return
    end

    // Server(auth, Info(env), HandleDot(env), logger
    //   where service=service, limit=limit, reversedns=auth
    // )
    Server(auth, Info(env), Handle, _logger
      where service = _port.string(), limit = _limit, reversedns = auth
    )

  fun ref arguments() ? =>
    let options = Options(_env)

    options.add("port", "p", I64Argument)
    options.add("logger", None, StringArgument)
    options.add("limit", "l", I64Argument)

    for option in options do 
      match option
      | ("port", let arg: I64) if arg > 0 => 
        _port = arg.u32()
        _env.out.print("port: " + _port.string())
      | ("limit", let arg: I64) if arg > 0 => 
        _limit = arg.usize()
        _env.out.print("limit: " + _limit.string())
      | ("logger", let arg: String) if arg.substring(0, 1).lower() == "d" =>
        _logger = DiscardLog
        _env.out.print("discard log")
      | ("logger", let arg: String) if arg.substring(0, 3).lower() == "com" =>
        _logger = CommonLog(_env.out)
        _env.out.print("common log")
      | ("logger", let arg: String) if arg.substring(0, 3).lower() == "con" =>
        _logger = ContentsLog(_env.out)
        _env.out.print("contents log")
      | let err: ParseError => 
        err.report(_env.out)
        usage()
        error
      end
    end

  fun usage() =>
    None

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