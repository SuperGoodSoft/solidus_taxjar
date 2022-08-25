RSpec.describe Spree::Shipment do
  describe '#update' do
    subject { shipment.ship }

    let(:shipment) { create(:shipment, state: 'ready', order: order) }
    let(:order) { create :order_with_line_items }

    it 'fires the shipment_shipped event exactly once' do
      expect(SolidusSupport::LegacyEventCompat::Bus)
        .to receive(:publish)
        .with(
          :shipment_shipped,
          shipment: shipment
        )
        .once

      subject
    end
  end
end
