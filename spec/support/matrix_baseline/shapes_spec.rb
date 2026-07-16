require "support/matrix_baseline/shapes"

module MatrixBaseline
  describe Shapes do
    let(:seed_result) do
      {
        consumers: Array.new(50) { |i| format("consumer-app-%02d", i + 1) },
        providers: Array.new(15) { |i| format("provider-service-%02d", i + 1) },
        both: Array.new(8) { |i| format("gateway-service-%02d", i + 1) },
        environment: "production",
        anchors: {
          consumer: "consumer-app-01",
          consumer_version: "1",
          provider: "provider-service-01",
          provider_version: "1",
          both: "gateway-service-01",
          downstream: ["provider-service-01", "gateway-service-01", "provider-service-02", "provider-service-03"],
        },
      }
    end
    subject(:shapes) { Shapes.call(seed_result) }

    SELECTOR_KEYS = [:pacticipant_name, :pacticipant_version_number].freeze
    OPTION_KEYS = [:latestby, :limit, :latest, :success, :environment_name].freeze

    it "produces the 10 representative shapes with stable ids" do
      expect(shapes.size).to eq(10)
      expect(shapes.map(&:id).uniq.size).to eq(10)
      expect(shapes.map(&:id)).to all(match(/\A[a-z0-9_]+\z/))
      expect(shapes.map(&:kind).uniq).to match_array([:matrix, :can_i_deploy])
    end

    it "builds valid UnresolvedSelectors and an options Hash per shape" do
      shapes.each do |shape|
        expect(shape.selectors).to all(be_a(PactBroker::Matrix::UnresolvedSelector))
        expect(shape.options).to be_a(Hash)
      end
    end

    it "includes a large-N shape with at least 20 selectors" do
      large_n = shapes.find { |s| s.id == "large_n_selectors" }
      expect(large_n.selectors.size).to be >= 20
    end

    it "includes a middle-tier shape selecting the both-service anchor" do
      middle_tier = shapes.find { |s| s.id == "middle_tier_matrix" }
      expect(middle_tier).not_to be_nil
      expect(middle_tier.selectors.size).to eq(1)
      expect(middle_tier.selectors.first[:pacticipant_name]).to eq(seed_result[:anchors][:both])
    end

    it "keeps engine options out of selectors and selector keys out of options" do
      shapes.each do |shape|
        shape.selectors.each do |selector|
          OPTION_KEYS.each { |key| expect(selector).not_to have_key(key) }
        end
        SELECTOR_KEYS.each { |key| expect(shape.options).not_to have_key(key) }
      end
    end
  end
end
