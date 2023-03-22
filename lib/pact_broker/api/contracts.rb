Dir.glob(File.expand_path(File.join(__FILE__, "..", "contracts", "*.rb"))).sort.each do | path |
  require path
end
