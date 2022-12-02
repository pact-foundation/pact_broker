require "webmachine/application"

class Webmachine::Application
  def application_context= application_context
    # naughty, but better than setting each route manually
    routes.each do | route |
      route.instance_variable_get(:@bindings)[:application_context] = application_context
    end
  end
end
