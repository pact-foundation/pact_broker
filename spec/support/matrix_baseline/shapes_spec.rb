require "support/matrix_baseline/shapes"

module MatrixBaseline
  describe Shapes do
    let(:seed_result) do
      {
        consumers: 1.upto(50).map { |i| "consumer-app-#{"%02d" % i}" },
        providers: 1.upto(15).map { |i| "provider-service-#{"%02d" % i}" },
        both: 1.upto(8).map { |i| "gateway-service-#{"%02d" % i}" },
        environment: "production",
        branch: "main",
        tag: "prod",
        anchors: {
          consumer: "consumer-app-01",
          consumer_version: "1",
          provider: "provider-service-01",
          provider_version: "1",
          both: "gateway-service-01",
          downstream: ["provider-service-01", "gateway-service-01", "provider-service-02", "provider-service-03"],
          wide_consumer: "wide-consumer-01",
          wide_consumer_version: "1",
        },
      }
    end
    subject(:shapes) { Shapes.call(seed_result) }

    SELECTOR_KEYS = [:pacticipant_name, :pacticipant_version_number, :branch, :tag].freeze
    # :latest is deliberately absent — it is a legitimate key on both a
    # selector (latest version of that pacticipant) and the options hash
    # (can-i-deploy's overall-latest mode), so it cannot separate the two.
    OPTION_KEYS = [:latestby, :limit, :success, :environment_name].freeze

    it "produces the 14 representative shapes with stable ids" do
      expect(shapes.size).to eq(14)
      expect(shapes.map(&:id).uniq.size).to eq(14)
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

    # large_n_selectors uses name-only selectors, which take the
    # only_pacticipant_name_specified? path and never build the version-
    # resolution UNION at all. This shape is the one that does.
    it "includes a large-N environment shape, the production shape this baseline exists to profile" do
      shape = shapes.find { |s| s.id == "can_i_deploy_environment_large_n" }

      expect(shape).to_not be_nil
      expect(shape.kind).to eq(:can_i_deploy)
      expect(shape.selectors.size).to eq(1)
      expect(shape.selectors.first[:pacticipant_name]).to eq("wide-consumer-01")
      expect(shape.selectors.first[:pacticipant_version_number]).to eq("1")
      expect(shape.options[:environment_name]).to eq("production")
    end

    it "includes a middle-tier shape selecting the both-service anchor" do
      middle_tier = shapes.find { |s| s.id == "middle_tier_matrix" }
      expect(middle_tier).not_to be_nil
      expect(middle_tier.selectors.size).to eq(1)
      expect(middle_tier.selectors.first[:pacticipant_name]).to eq(seed_result[:anchors][:both])
    end

    # Branch, tag and ignore selectors each resolve through a different path in
    # the query engine, so a baseline without them cannot show a regression there.
    it "covers branch-resolved, tag-resolved and ignored selectors" do
      branch_shape = shapes.find { |s| s.id == "branch_selector" }
      expect(branch_shape.selectors.first[:branch]).to eq("main")

      tag_shape = shapes.find { |s| s.id == "tag_selector" }
      expect(tag_shape.selectors.first[:tag]).to eq("prod")

      ignore_shape = shapes.find { |s| s.id == "can_i_deploy_ignore" }
      expect(ignore_shape.options[:ignore_selectors]).to all(be_a(PactBroker::Matrix::UnresolvedSelector))
      expect(ignore_shape.options[:ignore_selectors].first[:pacticipant_name]).to eq("provider-service-01")
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
