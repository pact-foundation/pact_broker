require 'spec_helper'

describe Approvals::Verifiers::JsonVerifier do
  subject(:instance) do
    described_class.new(received_path, approved_path)
  end

  context "with same json content but different formatting" do
    let(:received_path) do
      "./spec/fixtures/json_approval_with_different_whitespace/received.json"
    end
    let(:approved_path) do
      "./spec/fixtures/json_approval_with_different_whitespace/approved.json"
    end

    it "passes verification" do
      expect(instance.verify).to be_truthy
    end
  end

  context "with different json content" do
    let(:received_path) do
      "./spec/fixtures/json_approval_with_different_whitespace/received_different_content.json"
    end
    let(:approved_path) do
      "./spec/fixtures/json_approval_with_different_whitespace/approved.json"
    end

    it "does not passe verification" do
      expect(instance.verify).to be_falsy
    end
  end
end
