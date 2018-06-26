require 'reform'
require 'reform/form/dry'

Reform::Form.class_eval do
  feature Reform::Form::Dry
end

require 'pact_broker/api/resources/base_resource'

Dir.glob(File.expand_path(File.join(__FILE__, "..", "resources", "*.rb"))).sort.each do | path |
  require path
end
