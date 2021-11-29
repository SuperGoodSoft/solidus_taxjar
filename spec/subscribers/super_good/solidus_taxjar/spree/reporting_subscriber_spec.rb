require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Spree::ReportingSubscriber do
  describe "shipment_shipped is fired" do
    subject { ::Spree::Event.fire 'shipment_shipped', shipment: shipment  }

    let(:shipment) { create(:shipment, state: 'ready', order: order) }
    let(:order) { create :order_with_line_items }
    let(:reporting) { instance_spy(::SuperGood::SolidusTaxjar::Reporting) }

    context "reporting is enabled" do
      before do
        allow(::SuperGood::SolidusTaxjar)
          .to receive(:reporting_enabled)
          .and_return(true)
      end

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
      before do
        allow(::SuperGood::SolidusTaxjar)
          .to receive(:reporting_enabled)
          .and_return(false)
      end

      it "doesn't queue to report the transaction" do
        subject

        assert_no_enqueued_jobs
      end
    end
  end
end
