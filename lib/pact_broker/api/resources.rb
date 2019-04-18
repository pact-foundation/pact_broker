require 'pact_broker/api/resources/base_resource'

Dir.glob(File.expand_path(File.join(__FILE__, "..", "resources", "*.rb"))).sort.each do | path |
  require path
end
