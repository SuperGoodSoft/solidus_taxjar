require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::OrderTransaction do
  describe ".latest_for" do
    subject { described_class.latest_for(order) }

    let(:order) { create(:order) }

    context "when there are no order transactions" do
      it { is_expected.to be_nil }
    end

    context "when there are one or more order transactions" do
      let(:transaction_date) { 1.day.ago }

      let!(:first_order_transaction) {
        create(
          :taxjar_order_transaction,
          transaction_date: transaction_date,
          order: order
        )
      }
      let!(:latest_order_transaction) {
        create(
          :taxjar_order_transaction,
          transaction_date: transaction_date,
          order: order
        )
      }

      it "returns the most recent order transaction" do
        expect(subject).to eq latest_order_transaction
      end
    end
  end
end
