require 'pact_broker/pacts/verifiable_content_sha'

Sequel.migration do
  up do
    from(:pact_versions).each do | pact_version |

      if pact_version[:content]
        sha = PactBroker::Pacts::VerifiableContentSha.call(pact_version[:content])
        from(:pact_versions).where(id: pact_version[:id]).update(verifiable_content_sha: sha)
      end
    end
  end
end


