module PactBroker
  module Certificates
    class Certificate < Sequel::Model
    end

    Certificate.plugin :timestamps, update_on_create: true
  end
end
