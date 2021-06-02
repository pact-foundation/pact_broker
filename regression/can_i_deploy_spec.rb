require "pact_broker/domain"
PACTICIPANT_LIMIT = 10
VERSION_LIMIT = 10

PACTICIPANTS = PactBroker::Domain::Pacticipant.order(Sequel.desc(:id)).limit(PACTICIPANT_LIMIT).all

RSpec.describe "regression tests" do

  def can_i_deploy(pacticipant_name, version_number, to_tag)
    get("/can-i-deploy", { pacticipant: pacticipant_name, version: version_number, to: to_tag }, { "HTTP_ACCEPT" => "application/hal+json" })
  end

  PACTICIPANTS.each do | pacticipant |
    describe pacticipant.name do

      versions = PactBroker::Domain::Version.where(pacticipant_id: pacticipant.id).order(Sequel.desc(:order)).limit(VERSION_LIMIT)
      versions.each do | version |
        describe "version #{version.number}" do
          it "has the same results for can-i-deploy" do

            can_i_deploy_response = can_i_deploy(pacticipant.name, version.number, "prod")
            results = {
              request: {
                name: "can-i-deploy",
                params: {
                  pacticipant_name: pacticipant.name,
                  version_number: version.number,
                  to_tag: "prod"
                }
              },
              response: {
                status: can_i_deploy_response.status,
                body: JSON.parse(can_i_deploy_response.body)
              }
            }

            Approvals.verify(results, :name => "regression_can_i_deploy_#{pacticipant.name}_version_#{version.number}", format: :json)
          end
        end
      end
    end
  end
end
