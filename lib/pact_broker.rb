
require "zeitwerk"
Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/pact_broker/webmachine.rb")
loader.ignore("#{__dir__}/pact_broker/ui/helpers/haml_helpers.rb")  
loader.ignore("#{__dir__}/webmachine/application_monkey_patch.rb")  
loader.ignore("#{__dir__}/webmachine/render_error_monkey_patch.rb")
loader.setup

require "pact_broker/webmachine"
