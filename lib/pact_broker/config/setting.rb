module PactBroker
  module Config
    class Setting < Sequel::Model(:config)
    end

    Setting.plugin :timestamps, update_on_create: true
  end
end
