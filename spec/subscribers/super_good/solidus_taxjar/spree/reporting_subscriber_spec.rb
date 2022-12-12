require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Spree::ReportingSubscriber do
  # We only want to trigger the real event action behaviour as our spec
  # `subject`s.
  def with_events_disabled(&block)
    allow(Spree::Event).to receive(:fire).and_return(nil)

    object = yield block

    allow(Spree::Event).to receive(:fire).and_call_original

    object
  end

  before do
    create(:taxjar_configuration, preferred_reporting_enabled: reporting_enabled)
  end

  let(:order_factory) { :order_ready_to_ship }
  let(:order) { with_events_disabled { create order_factory } }

  let(:reporting) { instance_spy ::SuperGood::SolidusTaxjar::Reporting }
  let(:reporting_enabled) { true }

  describe "order_recalculated is fired" do
    subject do
      SolidusSupport::LegacyEventCompat::Bus.publish(
        :order_recalculated,
        order: order
      )
    end

    context "when the order is completed" do
      context "when the order has not been shipped" do
        it "does nothing" do
          expect(reporting)
            .not_to receive(:refund_and_create_new_transaction)

          subject
        end
      end

      context "when the order's payment state is 'credit_owed'" do
        let(:order) {
          with_events_disabled {
            create(order_factory, payment_state: "credit_owed")
          }
        }

        it "does nothing" do
          expect(reporting)
            .not_to receive(:refund_and_create_new_transaction)

          subject
        end
      end

      context "when the order's payment state is 'paid'" do
        context "when a TaxJar transaction already exists on the order" do
          let!(:taxjar_transaction) { create(:taxjar_order_transaction, order: order) }

          let(:dummy_client) { instance_double Taxjar::Client }
          let(:dummy_response) {
            instance_double(
              ::Taxjar::Order,
              amount: 110.00,
              line_items: [
                Taxjar::LineItem.new(
                  discount: 0,
                  sales_tax: 9999,
                  unit_price: 9999
                )
              ],
              sales_tax: 9999999,
              shipping: 99999,
              transaction_id: order.number,
              transaction_date: "2015-05-15T00:00:00Z"
            )
          }

          let(:new_dummy_response) {
            instance_double(
              ::Taxjar::Order,
              amount: 333.00,
              transaction_id: "#{order.number}-1",
              transaction_date: "2015-05-16T00:00:00Z"
            )
          }

          before do
            allow(SuperGood::SolidusTaxjar::Api)
              .to receive(:default_taxjar_client)
              .and_return(dummy_client)

            allow(dummy_client)
              .to receive(:show_order)
              .with(taxjar_transaction.transaction_id)
              .and_return(dummy_response)

            allow(dummy_client)
              .to receive(:create_refund)
              .with(
                SuperGood::SolidusTaxjar::ApiParams
                  .refund_transaction_params(order, dummy_response)
              )
          end

          context "when the TaxJar transaction is up-to-date" do
            it "does nothing" do
              expect(reporting)
                .not_to receive(:refund_and_create_new_transaction)

              subject
            end

            context "when reporting is disabled" do
              let(:reporting_enabled) { false }

              it "does nothing" do
                expect(reporting)
                  .not_to receive(:refund_and_create_new_transaction)

                subject
              end
            end
          end

          context "when the TaxJar transaction is not up-to-date" do
            before do
              allow(dummy_client).to receive(:nexus_regions)
              allow(dummy_client).to receive(:tax_for_order)

              with_events_disabled {
                # We want to ensure that the order is completed, paid, and that
                # the `ReportingSubscriber#amount_changed?` method returns true.
                order.line_items.first.update!(price: 33)
                order.recalculate
                order.payments.first.update!(amount: order.total)
              }
            end

            it "enqueue a job to refund and create a new transaction" do
              assert_enqueued_with(
                job: SuperGood::SolidusTaxjar::ReplaceTransactionJob,
                args: [order]
              ) do
                subject
              end
            end

            context "when reporting is disabled" do
              let(:reporting_enabled) { false }

              it "does nothing" do
                expect(reporting)
                  .not_to receive(:refund_and_create_new_transaction)

                subject
              end
            end
          end
        end

        context "when a TaxJar transaction does not exist on the order" do
          it "does nothing" do
            expect(reporting)
              .not_to receive(:refund_and_create_new_transaction)

            subject
          end

          it(
            "creates a new transaction",
            skip: "in the future, we would like to implement a 'create or update' flow"
          ) do
            expect { subject }
              .to change { SuperGood::SolidusTax::OrderTransaction.count }
              .from(0)
              .to(1)
          end
        end
      end

      context "when the order's payment state is 'balance_due'" do
        let(:order_factory) { :completed_order_with_pending_payment }

        it "does nothing" do
          expect(reporting).not_to receive(:show_or_create_transaction)
          subject
        end
      end
    end

    context "when the order is not completed" do
      let(:order_factory) { :order_with_totals }

      it "does nothing" do
        expect(reporting).not_to receive(:show_or_create_transaction)
        subject
      end
    end
  end

  describe "shipment_shipped is fired" do
    subject do
      SolidusSupport::LegacyEventCompat::Bus.publish(
        :shipment_shipped,
        shipment: shipment
      )
    end

    before do
      # Ignore other events that may be triggered by factories here.
      allow(Spree::Event).to receive(:fire).with("order_recalculated")
    end

    let(:shipment) { create(:shipment, state: 'ready', order: order) }
    let(:order) {
      with_events_disabled { create :order_with_line_items }
    }
    let(:reporting) { instance_spy(::SuperGood::SolidusTaxjar::Reporting) }

    context "reporting is enabled" do
      it "enqueues job to report transaction" do
        assert_enqueued_with(
          job: SuperGood::SolidusTaxjar::ReportTransactionJob,
          args: [shipment.order]
        ) do
          subject
        end
      end
    end

    context "reporting is disabled" do
      let(:reporting_enabled) { false }

      it "doesn't queue to report the transaction" do
        subject

        assert_no_enqueued_jobs
      end
    end
  end
end
