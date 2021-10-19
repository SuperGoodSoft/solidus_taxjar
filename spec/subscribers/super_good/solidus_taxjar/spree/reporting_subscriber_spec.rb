require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Spree::ReportingSubscriber do
  describe "shipment_shipped is fired" do
    subject { ::Spree::Event.fire 'shipment_shipped', shipment: shipment  }

    let(:shipment) { build_stubbed(:shipment, state: 'ready', order: order) }
    let(:order) { build_stubbed :order_with_line_items }
    let(:reporting) { instance_spy(::SuperGood::SolidusTaxjar::Reporting) }

    context "reporting is enabled" do
      before do
        allow(::SuperGood::SolidusTaxjar)
          .to receive(:reporting_enabled)
          .and_return(true)

        allow(::SuperGood::SolidusTaxjar)
          .to receive(:reporting)
          .and_return(reporting)
      end

      it "reports transaction" do
        expect(reporting)
          .to receive(:report_transaction)
          .with(shipment.order)

        subject
      end
    end

    context "reporting is disabled" do
      before do
        allow(::SuperGood::SolidusTaxjar)
          .to receive(:reporting_enabled)
          .and_return(false)
      end

      it "returns nothing" do
        expect(subject).to be_nil
      end

      it "doesn't report the transaction" do
        expect(reporting)
          .to_not receive(:report_transaction)

        subject
      end
    end
  end
end
