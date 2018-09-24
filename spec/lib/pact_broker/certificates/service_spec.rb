require 'pact_broker/certificates/service'

module PactBroker
  module Certificates
    describe Service do
      let(:certificate_content) { File.read('spec/fixtures/certificate.pem') }
      let(:logger) { double('logger').as_null_object }

      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      describe "#cert_store" do
        subject { Service.cert_store }

        it "returns an OpenSSL::X509::Store" do
          expect(subject).to be_instance_of(OpenSSL::X509::Store)
        end

        context "when there is a duplicate certificate" do
          before do
            Certificate.create(uuid: '1234', content: certificate_content)
            Certificate.create(uuid: '5678', content: certificate_content)
          end

          it "logs the error" do
            expect(Service).to receive(:log_error).with(anything, /Error adding certificate/).at_least(1).times
            subject
          end

          it "returns an OpenSSL::X509::Store" do
            expect(subject).to be_instance_of(OpenSSL::X509::Store)
          end
        end
      end

      describe "#find_all_certificates" do
        let!(:certificate) do
          Certificate.create(uuid: '1234', content: certificate_content)
        end

        subject { Service.find_all_certificates }

        context "with a valid certificate chain" do
          it "returns all the X509 Certificate objects" do
            expect(subject.size).to eq 2
          end
        end

        context "with a valid CA file" do
          let(:certificate_content) { File.read('spec/fixtures/certificates/cacert.pem') }

          it "returns all the X509 Certificate objects" do
            expect(logger).to_not receive(:error).with(/Error.*1234/)
            expect(subject.size).to eq 1
          end
        end

        context "with an invalid certificate file" do
          let(:certificate_content) { File.read('spec/fixtures/certificate-invalid.pem') }

          it "logs an error" do
            expect(logger).to receive(:error).with(/Error.*1234/)
            subject
          end

          it "returns all the valid X509 Certificate objects" do
            expect(subject.size).to eq 1
          end
        end
      end
    end
  end
end
