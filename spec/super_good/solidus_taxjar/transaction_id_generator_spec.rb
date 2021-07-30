require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::TransactionIdGenerator do
  describe ".next_transaction_id" do
    subject {
      described_class.next_transaction_id(
        order: order,
        current_transaction_id: current_transaction_id
      )
    }

    let(:order) { build :order, number: order_number }
    let(:order_number) { "R1234567890" }

    context "without a `current_transaction_id`" do
      subject { described_class.next_transaction_id(order: order) }

      it "uses the order.number as the transaction_id" do
        expect(subject).to eq("R1234567890")
      end

      context "and there are dashes in the order number" do
        let(:order_number) { "R123-456-7890" }

        it "uses the order.number as the transaction_id" do
          expect(subject).to eq("R123-456-7890")
        end
      end
    end

    context "with a `current_transaction_id`" do
      context "when the current transaction ID does not have a suffix" do
        let(:order_number) { "R1234567890" }
        let(:current_transaction_id) { "R1234567890" }

        it "generates the next sequential transaction_id" do
          expect(subject).to eq("R1234567890-1")
        end
      end

      context "when the current transaction ID has a suffix" do
        let(:order_number) { "R1234567890" }
        let(:current_transaction_id) { "R1234567890-2" }

        it "generates the next sequential transaction_id" do
          expect(subject).to eq("R1234567890-3")
        end
      end

      context "when the current transaction ID contains more than one '-'" do
        let(:order_number) { "R123-456-789-0" }
        let(:current_transaction_id) { "R123-456-789-0-2" }

        it "generates the next sequential transaction_id" do
          expect(subject).to eq("R123-456-789-0-3")
        end
      end

      context "when the current transaction ID suffix rolls over" do
        let(:order_number) { "R1234567890" }
        let(:current_transaction_id) { "R1234567890-99" }

        it "generates the next sequential transaction_id" do
          expect(subject).to eq("R1234567890-100")
        end
      end
    end
  end

  describe ".refund_transaction_id" do
    subject { described_class.refund_transaction_id(transaction_id) }

    let(:transaction_id) { "R1234567890" }

    it { is_expected.to eq("R1234567890-REFUND") }
  end
end
