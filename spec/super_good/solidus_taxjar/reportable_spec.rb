require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Reportable do
  class ReportableTestClass
    include SuperGood::SolidusTaxjar::Reportable

    def initialize(order)
      @order = order
    end

    def test_with_reportable
      with_reportable(@order) do
        return true
      end
      false
    end

    def test_with_replaceable
      with_replaceable(@order) do
        return true
      end
      false
    end
  end

  let(:reportable_test_class) { ReportableTestClass.new(order) }

  describe "#with_reportable" do
    subject { reportable_test_class.test_with_reportable }

    let!(:taxjar_configuration) { create(:taxjar_configuration, preferred_reporting_enabled_at_integer: nil) }

    let(:order) { create(:order) }

    it { is_expected.to be_falsey }

    context "when reporting is enabled" do
      let!(:taxjar_configuration) { create(:taxjar_configuration,   preferred_reporting_enabled_at_integer: 1.hour.ago) }

      it { is_expected.to be_falsey }

      context "is completed" do
        let(:order) { create(:completed_order_with_totals) }

        it { is_expected.to be_falsey }

        context "is shipped" do
          let(:order) { create(:shipped_order) }

          it { is_expected.to be_truthy }

          context "the order is not paid" do
            before do
              order.update_columns(payment_state: :balance_due)
            end

            it { is_expected.to be_falsey }
          end

          context "when the order has a failed transaction sync log and no order transactions" do
            before do
              create :transaction_sync_log, :error, order: order
            end

            it { is_expected.to be_truthy }
          end

          context "when the order has a failed transaction sync log, and an existing order transaction" do
            before do
              create :transaction_sync_log, :error, order: order
              create :taxjar_order_transaction, order: order
            end

            it { is_expected.to be_falsey }
          end

          context "when the order was completed before reporting was enabled" do
            before do
              allow(SuperGood::SolidusTaxjar.exception_handler)
                .to receive(:call)

              order.update_columns(completed_at: 2.days.ago)
            end

            it { is_expected.to be_falsey }

            it "creates a sync log with an error" do
              expect { subject }
                .to change { order.taxjar_transaction_sync_logs.count }
                .from(0)
                .to(1)

              expect(order.taxjar_transaction_sync_logs.last).to have_attributes(
                status: "error",
                error_message: "Order cannot be synced because it was completed before TaxJar reporting was enabled"
              )
            end

            it "calls the solidus taxjar exception handler with the error" do
              subject

              expect(SuperGood::SolidusTaxjar.exception_handler)
                .to have_received(:call)
                .with(RuntimeError.new("Order cannot be synced because it was completed before TaxJar reporting was enabled"))
            end
          end
        end
      end
    end
  end

  describe "#with_replaceable" do
    subject { reportable_test_class.test_with_replaceable }

    let!(:taxjar_configuration) { create(:taxjar_configuration, preferred_reporting_enabled_at_integer: nil) }

    let(:order) { create(:order) }

    it { is_expected.to be_falsey }

    context "when reporting is enabled and the order is completed and shipped" do
      let!(:taxjar_configuration) { create(:taxjar_configuration,   preferred_reporting_enabled_at_integer: 1.hour.ago) }
      let(:order) do
        order = create(:completed_order_with_pending_payment)
        order.update_columns(shipment_state: :shipped)
        order
      end
      let(:last_transaction_amount) { order.payment_total - order.additional_tax_total }
      let(:dummy_api) { instance_double ::SuperGood::SolidusTaxjar::Api }

      before do
        allow(dummy_api)
          .to receive(:show_latest_transaction_for)
          .and_return(double(amount: last_transaction_amount))
        allow(SuperGood::SolidusTaxjar)
          .to receive(:api)
          .and_return(dummy_api)
      end

      it { is_expected.to be_falsey }

      context "when the order has a previous taxjar transaction" do
        before do
          create(:taxjar_order_transaction, order: order)
        end

        it { is_expected.to be_falsey }

        context "when the order is paid" do
          let(:order) { create :shipped_order }

          it { is_expected.to be_falsey }

          context "when the order's amount has changed" do
            let(:last_transaction_amount) { order.payment_total - 12 }

            it { is_expected.to be_truthy }

            context "when the order was completed before reporting was enabled" do
              before do
                allow(SuperGood::SolidusTaxjar.exception_handler)
                  .to receive(:call)

                order.update_columns(completed_at: 2.days.ago)
              end

              it { is_expected.to be_falsey }

              it "creates a sync log with an error" do
                expect { subject }
                  .to change { order.taxjar_transaction_sync_logs.count }
                  .from(0)
                  .to(1)

                expect(order.taxjar_transaction_sync_logs.last).to have_attributes(
                  status: "error",
                  error_message: "Order cannot be synced because it was completed before TaxJar reporting was enabled"
                )
              end

              it "calls the solidus taxjar exception handler with the error" do
                subject

                expect(SuperGood::SolidusTaxjar.exception_handler)
                  .to have_received(:call)
                  .with(RuntimeError.new("Order cannot be synced because it was completed before TaxJar reporting was enabled"))
              end
            end
          end
        end
      end
    end
  end
end
