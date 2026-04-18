require "pathname"

module PactBroker
  module ProjectRoot
    def self.path
      @path ||= Pathname.new(File.expand_path("../../../",__FILE__)).freeze
    end
  end
  
  def self.project_root
    ProjectRoot.path
  end
end
