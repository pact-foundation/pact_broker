require_relative 'db'
require 'json'

def with_timestamps hash
  hash.merge(created_at: DateTime.now, updated_at: DateTime.now)
end

consumer_id = DB[:pacticipants].insert(with_timestamps(name: 'Foo'))
provider_id = DB[:pacticipants].insert(with_timestamps(name: 'Bar'))
version_id = DB[:versions].insert(with_timestamps(number: '1.2.3', pacticipant_id: consumer_id))
pact_json = {consumer: {name: 'Foo'}, provider: {name: 'Bar'}, interactions: []}.to_json
pact_version_id = DB[:pact_versions].insert(sha: '123', content: pact_json, created_at: DateTime.now, consumer_id: consumer_id, provider_id: provider_id)
pact_publication_id = DB[:pact_publications].insert(consumer_version_id: version_id, provider_id: provider_id, revision_number: 1, pact_version_id: pact_version_id, created_at: DateTime.now)
