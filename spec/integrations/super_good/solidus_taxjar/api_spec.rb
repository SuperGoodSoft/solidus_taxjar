require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Api do
  describe "#tax_for" do
    subject { api.tax_for order }

    let(:api) { described_class.new }
    let(:ship_address) { create(:address, zipcode: "35242", state_code: "AL") }
    let(:order) { create :order_with_line_items, ship_address: ship_address }

    around do |example|
      # Orders in certain states will automatically try
      # to calculate tax. We want to prevent this so
      # only the desired API calls are made.
      old_value = SuperGood::SolidusTaxjar.test_mode
      SuperGood::SolidusTaxjar.test_mode = true
      example.run
      SuperGood::SolidusTaxjar.test_mode = old_value
    end

    it "logs the response details", vcr: true do
      allow(Rails.logger).to receive(:info)
      subject
      expect(Rails.logger)
        .to have_received(:info)
        .with("[SUCCESS] POST /v2/taxes/tax")
    end
  end
end
