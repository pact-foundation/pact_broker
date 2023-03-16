require "webmachine"
require "webmachine/application_monkey_patch"
require "webmachine/adapters/rack_mapped"
require "webmachine/application_monkey_patch"
require "webmachine/render_error_monkey_patch"


module Webmachine
  def self.build_rack_api(application_context)
    api = Webmachine::Application.new do |app|
      yield app
    end

    api.application_context = application_context

    api.configure do |config|
      config.adapter = :RackMapped
    end

    api.adapter
  end
end
