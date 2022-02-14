require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::BackfillTransactions do
  describe ".call" do
    subject { described_class.new(api: api_spy).call }

    let!(:shipped_order) { create :shipped_order }
    let(:api_spy) { instance_spy(::SuperGood::SolidusTaxjar::Api) }

    around do |example|
      ::SuperGood::SolidusTaxjar.test_mode = true
      example.run
      ::SuperGood::SolidusTaxjar.test_mode = false
    end

    before do
      reported_order = create :shipped_order
      create(:taxjar_order_transaction, order: reported_order)
      create :order_ready_to_ship
    end

    it "reports all completed and shipped orders to taxjar" do
      subject
      expect(api_spy).to have_received(:create_transaction_for).once
      expect(api_spy).to have_received(:create_transaction_for).with(shipped_order)
    end

    it "returns the numbers of the orders that have been pushed" do
      expect(subject).to eq([shipped_order.number])
    end
  end
end
