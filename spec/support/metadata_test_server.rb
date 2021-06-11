if __FILE__ == $0
  require "json"
  require "base64"
  STDOUT.sync = true

  trap(:INT) do
    @server.shutdown
    exit
  end

  def webrick_opts port
    {
      Port: port,
      Host: "0.0.0.0",
      AccessLog: [],
    }
  end

  app = ->(env) do
    env["rack.input"].rewind
    body_hash = JSON.parse(env["rack.input"].read)
    metadata = body_hash["pactUrl"].split("/").last

    metadata_string = Base64.strict_decode64(metadata)
    metadata = Rack::Utils.parse_nested_query(metadata_string)
    # hash = JSON.parse(json)
    [200, {}, [metadata.to_json]]

  end

  require "webrick"
  require "rack"
  require "rack/handler/webrick"

  opts = webrick_opts(4445)

  Rack::Handler::WEBrick.run(app, opts) do |server|
    @server = server
  end
end
