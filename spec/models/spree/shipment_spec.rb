RSpec.describe Spree::Shipment do
  describe '#update' do
    subject { shipment.ship }

    let(:shipment) { create(:shipment, state: 'ready', order: order) }
    let(:order) { create :order_with_line_items }

    before do
      # Prevent client from being instantiated in test environment.
      allow(SuperGood::SolidusTaxjar).to receive(:api)
    end

    it 'fires the shipment_shipped event exactly once' do
      stub_const('Spree::Event', class_spy(Spree::Event))

      expect(Spree::Event).to receive(:fire).with('shipment_shipped', shipment: shipment).once

      subject
    end
  end
end
