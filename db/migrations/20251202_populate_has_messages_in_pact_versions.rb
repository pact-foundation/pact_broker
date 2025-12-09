require "pact_broker/pacts/content"
require "pact_broker/pacts/interactions/types"

Sequel.migration do
  up do
    batch_size = 500
    offset = 0

    loop do
      rows = from(:pact_versions).order(:id).limit(batch_size).offset(offset).all
      break if rows.empty?

      rows.each do |row|
        content = PactBroker::Pacts::Content.from_json(row[:content])
        has_messages = PactBroker::Pacts::Interactions::Types.for(content).has_messages?

        from(:pact_versions)
          .where(id: row[:id])
          .update(has_messages: has_messages)
      end

      offset += batch_size
    end
  end

  down do

  end
end
