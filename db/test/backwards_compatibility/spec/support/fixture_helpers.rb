require "json"

module FixtureHelpers
  def load_fixture(file_name)
    File.read(File.join("./spec/fixtures", file_name))
  end

  def load_json_fixture(file_name)
    require "json"
    JSON.parse(load_fixture(file_name))
  end
end
