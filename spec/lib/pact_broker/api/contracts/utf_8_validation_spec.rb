require "pact_broker/api/contracts/utf_8_validation"

module PactBroker
  module Api
    module Contracts
      describe UTF8Validation do
        describe ".fragment_before_invalid_utf_8_char" do
          subject { UTF8Validation.fragment_before_invalid_utf_8_char(string) }

          context "with a valid UTF-8 string" do
            let(:string) { "abc ünïcødé 😀" }

            it { is_expected.to be nil }
          end

          context "with a large valid UTF-8 string" do
            let(:string) { "abc ünïcødé 😀" * 10_000 }

            it { is_expected.to be nil }

            it "does not allocate an object per char" do
              allocated_objects_before = GC.stat(:total_allocated_objects)
              subject
              expect(GC.stat(:total_allocated_objects) - allocated_objects_before).to be < 100
            end
          end

          context "with a binary string containing valid UTF-8 bytes" do
            let(:string) { "abc ünïcødé".b }

            it { is_expected.to be nil }

            it "forces the encoding to UTF-8" do
              subject
              expect(string.encoding).to eq Encoding::UTF_8
            end
          end

          context "with an invalid UTF-8 char within the first 100 chars" do
            let(:string) { "abc\xFFdef".b }

            it "returns the char number and the fragment before the invalid char" do
              expect(subject).to eq [4, "abc"]
            end
          end

          context "with an invalid UTF-8 char after the first 100 chars" do
            let(:string) { ("a" * 150 + "b" * 100 + "\xFF" + "def").b }

            it "returns the char number and the 100 chars before the invalid char" do
              expect(subject).to eq [251, "b" * 100]
            end
          end

          context "with multibyte chars before the invalid char" do
            let(:string) { "ü😀\xFF".b }

            it "returns the char number, counting chars rather than bytes" do
              expect(subject).to eq [3, "ü😀"]
            end
          end
        end
      end
    end
  end
end
