require "spec_helper"
RSpec.describe SuperGood::SolidusTaxjar::Reporting do
  describe "#report_transaction" do
    subject { described_class.new(api: dummy_api).report_transaction(order) }

    let(:dummy_api) {
      instance_double ::SuperGood::SolidusTaxjar::Api
    }
    
    let(:order) { build :order, completed_at: 1.days.ago }
    
    it "updates the transaction" do
      allow(dummy_api)
        .to receive(:show_latest_transaction_for)
        .with(order)
        .and_return("UPDATED-TRANSACTION-ID")

      expect(subject).to eq("UPDATED-TRANSACTION-ID")
    end

    context "order doesn't have a transaction" do
      it "creates the transaction for it" do
        allow(dummy_api)
          .to receive(:show_latest_transaction_for)
          .with(order)
          .and_raise(Taxjar::Error::NotFound)

        expect(dummy_api)
          .to receive(:create_transaction_for)
          .with(order)
          .and_return({})

        subject 
      end
    end
  end
end
