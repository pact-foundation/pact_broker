require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    create_or_replace_view(:all_pacts,
      "select pacts.id,
      c.id as consumer_id, c.name as consumer_name,
      cv.id as consumer_version_id, cv.number as consumer_version_number, cv.`order` as consumer_version_order,
      p.id as provider_id, p.name as provider_name,
      pvc.sha as pact_version_content_sha,
      pacts.created_at, pacts.updated_at
      from pacts
        inner join versions as cv on (cv.id = pacts.version_id)
        inner join pacticipants as c on (c.id = cv.pacticipant_id)
        inner join pacticipants as p on (p.id = pacts.provider_id)
        inner join pact_version_contents as pvc on (pvc.sha = pacts.pact_version_content_sha)")

  end
end
