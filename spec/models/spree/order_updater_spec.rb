RSpec.describe Spree::OrderUpdater do
  describe '#update' do
    before do
      # Prevent client from being instantiated in test environment.
      allow(SuperGood::SolidusTaxjar).to receive(:api)
    end

    it 'fires the order_recalculated event exactly once' do
      stub_const('Spree::Event', class_spy(Spree::Event))
      order = create(:order)

      described_class.new(order).update

      expect(Spree::Event).to have_received(:fire).with('order_recalculated', order: order).once
    end
  end
end
