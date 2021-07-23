require "pact_broker/errors/error_logger"

module PactBroker
  module Errors
    describe ErrorLogger do
      before do
        allow(ErrorLogger).to receive(:logger).and_return(logger)
        allow(error).to receive(:backtrace).and_return(["backtrace"])
        allow(PactBroker::Errors).to receive(:reportable_error?).and_return(reportable)
      end

      let(:logger) { double("logger").as_null_object }
      let(:error) { StandardError.new("test error") }
      let(:env) { double("env") }
      let(:error_reference) { "bYWfnyWPlf" }
      let(:reportable) { true }

      subject { ErrorLogger.call(error, error_reference, env) }

      context "when the error class is in the warning_error_classes list" do
        before do
          allow(PactBroker.configuration).to receive(:warning_error_classes).and_return([Sequel::ForeignKeyConstraintViolation])
        end
        let(:error) { Sequel::ForeignKeyConstraintViolation.new }

        it "logs at warn so as not to wake everyone up in the middle of the night" do
          expect(logger).to receive(:warn).with(/bYWfnyWPlf/, error)
          subject
        end
      end

      context "when the error cause class is in the warning_error_classes list" do
        class TestCauseError < StandardError; end

        before do
          allow(PactBroker.configuration).to receive(:warning_error_classes).and_return([TestCauseError])
          allow(error).to receive(:cause).and_return(TestCauseError.new)
        end

        let(:error) { StandardError.new("message") }

        it "logs at warn so as not to wake everyone up in the middle of the night" do
          expect(logger).to receive(:warn).with(/bYWfnyWPlf/, error)
          subject
        end
      end

      context "when the error is reportable" do
        it "logs at error" do
          expect(ErrorLogger).to receive(:log_error).with(error, /bYWfnyWPlf/)
          subject
        end
      end

      context "when the error is not reportable and not a warning level" do
        let(:reportable) { false }

        it "logs at info" do
          expect(logger).to receive(:info).with(/bYWfnyWPlf/, error)
          subject
        end
      end
    end
  end
end
