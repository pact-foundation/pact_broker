require 'digest/sha1'
require_relative 'migration_helper'

Sequel.migration do
  change do
    self[:pacts].each do | row |
      sha = Digest::SHA1.hexdigest(row[:json_content])
      if self[:pact_version_contents].where(sha: sha).count == 0
        self[:pact_version_contents].insert(sha: sha, content: row[:json_content], created_at: row[:created_at], updated_at: row[:updated_at])
      end
      self[:pacts].where(id: row[:id]).update(pact_version_content_sha: sha)
    end
  end
end
