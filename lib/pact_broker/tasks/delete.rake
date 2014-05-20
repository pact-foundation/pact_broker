namespace :pact_broker do

  namespace :pacticipant do

    desc 'Delete pacticipant and all pacts, tags and versions related to that pacticipant'
    task :delete, [:name] do | task, args |
      name = args.to_hash.fetch(:name)
      puts "Deleting pacticipant '#{name}' and all related pacts, tags and versions"
      require 'sequel'
      require 'pact_broker/models/pacticipant'
      connection = PactBroker::Models::Pacticipant.new.db
      connection.run("delete from tags where version_id IN (select id from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}'))")
      connection.run("delete from pacts where version_id IN (select id from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}'))")
      connection.run("delete from pacts where provider_id IN (select id from pacticipants where name = '#{name}')")
      connection.run("delete from versions where pacticipant_id IN (select id from pacticipants where name = '#{name}')")
      connection.run("delete from pacticipants where name = '#{name}'")
    end
  end

end
