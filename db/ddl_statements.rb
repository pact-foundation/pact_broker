Dir.glob(File.expand_path(File.join(__FILE__, "..", "ddl_statements", "*.rb"))).sort.each do | path |
  require path
end
