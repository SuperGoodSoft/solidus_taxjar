RSpec.describe Taxjar::API::Request, :vcr do
  subject { Taxjar::API::Request.new(client, :get, '/v2/summary_rates', 'summary_rates').perform }

  let(:logger) { double(Logger) }
  let(:client) { Taxjar::Client.new(api_key: ENV["TAXJAR_API_KEY"], api_url: "https://api.sandbox.taxjar.com") }

  before do
    allow(SuperGood::SolidusTaxjar).to receive(:logger).and_return(logger)
  end


  context "logging is enabled" do
    before do
      allow(SuperGood::SolidusTaxjar).to receive(:logging_enabled).and_return(true)
    end

    it "calls the logger", :aggregate_failures do
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)

      subject

      # When recording a cassette with VCR for this spec, one extra log
      # statement is generated. In general we expect this to be called twice,
      # but specify at least 2 times so cassettes can be re-recorded.
      expect(logger).to have_received(:debug).at_least(2).times do |&block|
        expect(block.call)
          .to match("Host: api.sandbox.taxjar.com")
          .or(match(/"summary_rates":/))
      end

      expect(logger).to have_received(:info).at_least(2).times do |&block|
        expect(block.call)
          .to match("> GET https://api.sandbox.taxjar.com/v2/summary_rates")
          .or(match("< 200 OK"))
      end
    end
  end

  context "logging is disabled" do
    before do
      allow(SuperGood::SolidusTaxjar).to receive(:logging_enabled).and_return(false)
    end

    it "doesn't call the logger" do
      expect(logger).to_not receive(:debug)
      expect(logger).to_not receive(:info)

      subject
    end
  end
end
