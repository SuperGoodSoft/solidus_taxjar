require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Spree::ReportingSubscriber do
  describe "shipment_shipped is fired" do
    subject { ::Spree::Event.fire 'shipment_shipped', shipment: shipment  }

    let(:shipment) { create(:shipment, state: 'ready', order: order) }
    let(:order) { create :order_with_line_items }

    it "reports transaction" do
      reporting = instance_spy(::SuperGood::SolidusTaxjar::Reporting)

      allow(::SuperGood::SolidusTaxjar)
        .to receive(:reporting)
        .and_return(reporting)

      expect(reporting)
        .to receive(:report_transaction)
        .with(shipment.order)

      subject
    end
  end
end
