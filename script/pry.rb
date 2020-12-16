#!/usr/bin/env ruby

# raise "Please supply database path" unless ARGV[0]

$LOAD_PATH.unshift './lib'
$LOAD_PATH.unshift './spec'
$LOAD_PATH.unshift './tasks'
ENV['RACK_ENV'] = 'development'
require 'sequel'
require 'logger'
#DATABASE_CREDENTIALS = {logger: Logger.new($stdout), adapter: "sqlite", database: ARGV[0], :encoding => 'utf8'}.tap { |it| puts it }
DATABASE_CREDENTIALS = {
  adapter: "postgres", database: "postgres", username: 'postgres', password: 'postgres', host: "localhost",
  :encoding => 'utf8',
  driver_options: { options: "-c statement_timeout=5s" },
  logger: Logger.new($stdout)
}

connection = Sequel.connect(DATABASE_CREDENTIALS)
connection.timezone = :utc
# connection.extension(:statement_timeout)
# Uncomment these lines to open a pry session for inspecting the database

COLS = [:id, :consumer_name, :provider_name, :consumer_version_order]
old = Sequel::Model.db[:latest_tagged_pact_publications].select(*COLS)

orders = Sequel.as(:latest_tagged_pact_consumer_version_orders, :o)
lp_join = {
  Sequel[:lp][:consumer_id] => Sequel[:o][:consumer_id],
  Sequel[:lp][:provider_id] => Sequel[:o][:provider_id],
  Sequel[:versions][:order] => Sequel[:o][:latest_consumer_version_order]
}

thing = Sequel::Model.db[orders].select(
    Sequel[:lp][:id],
    Sequel[:consumers][:name].as(:consumer_name),
    Sequel[:providers][:name].as(:provider_name),
    Sequel[:lp][:consumer_version_order]
  )
  .join(:versions, { Sequel[:lp][:consumer_version_id] => Sequel[:versions][:id] })
  .join(:latest_pact_publication_ids_for_consumer_versions, lp_join, { table_alias: :lp })
  .join(:pacticipants, { Sequel[:o][:provider_id] => Sequel[:providers][:id] }, { table_alias: :providers })
  .join(:pacticipants, { Sequel[:o][:consumer_id] => Sequel[:consumers][:id] }, { table_alias: :consumers })


#   view = Sequel.as(:latest_pact_publication_ids_for_consumer_versions, :lp)
#   connection.from(view)
#     .select_group(
#       Sequel[:lp][:provider_id],
#       Sequel[:lp][:consumer_id],
#       Sequel[:t][:name].as(:tag_name))
#     .select_append{ max(version_order).as(latest_consumer_version_order) }
#     .join(:tags, { Sequel[:t][:version_id] => Sequel[:lp][:consumer_version_id] }, { table_alias: :t })


# tags_lp_join = {
#   Sequel[:lp][:consumer_id] => Sequel[:o][:consumer_id],
#   Sequel[:lp][:provider_id] => Sequel[:o][:provider_id],
#   Sequel[:tags][:order] => Sequel[:o][:latest_consumer_version_order]
# }

# lp_tags_join = { Sequel[:lp][:consumer_version_id] => Sequel[:tags][:version_id] }

# joined_self = Sequel::Model.db[:tags]
#   .select(Sequel[:lp][:id])
#   .join(:latest_pact_publication_ids_for_consumer_versions, lp_tags_join, { table_alias: :lp })

# Sequel::Model.db[:tags]
#   .select(Sequel[:lp][:id])
#   .join(:latest_pact_publication_ids_for_consumer_versions, lp_tags_join, { table_alias: :lp })
#   .join


tag_pp_join = {
  Sequel[:lp][:consumer_version_id] => Sequel[:tags][:version_id],
  Sequel[:tags][:name] => tag.name
}
Sequel::Model.db[:tags].join(:latest_pact_publication_ids_for_consumer_versions, tag_pp_join) do
  Sequel[:tags][:version_order] > tag.version_order
end


# select lp.id, o.tag_name
#       latest_tagged_pact_consumer_version_orders o
#       inner join latest_pact_publications_by_consumer_versions lp
#       on lp.consumer_id = o.consumer_id
#         and lp.provider_id = o.provider_id
#         and lp.consumer_version_order = latest_consumer_version_order






require 'pact_broker/db'
require 'pact_broker'
require 'support/test_data_builder'


require 'pry'; pry(binding);
puts "finished"
