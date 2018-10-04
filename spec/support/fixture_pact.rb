module Pact
  module Fixture

    def self.fixtures
      @@fixtures ||= []
    end

    def self.clear_fixtures
      @@fixtures = []
    end

    def register_fixture name
      source = caller.first
      thing = yield
      Fixture.fixtures << OpenStruct.new(name: name, thing: thing, source: source)
      thing
    end

    def self.check_fixtures
      fixtures.group_by(&:name).each do | name, fixture_group |
        if fixture_group.size == 1
          puts "WARN: Nothing to compare #{name} to."
        else
          if fixture_group.collect(&:thing).uniq.length != 1
            desc = fixture_group.collect do | fixture |
              "#{fixture.thing} from #{fixture.source}\n"
            end.join("\n")
            raise "These fixtures don't match #{fixture_group.first.name}:\n #{desc}"
          end
        end
      end
    end
  end
end
