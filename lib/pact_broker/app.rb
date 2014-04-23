module PactBroker

  APP = Rack::URLMap.new(
  '/' => PactBroker::API
  )

end