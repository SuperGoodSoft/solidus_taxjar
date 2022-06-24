RSpec.describe Spree::OrderUpdater do
  describe '#update' do
    subject { described_class.new(order).update }

    let(:order) { create(:order) }

    module TestSubscriber
      include Spree::Event::Subscriber
      include SolidusSupport::LegacyEventCompat::Subscriber

      event_action :order_recalculated

      def order_recalculated(_event)
      end
    end

    if SolidusSupport::LegacyEventCompat.using_legacy?
      let(:event_type_class) { ActiveSupport::Notifications::Event }

      before do
        if TestSubscriber.respond_to?(:subscribe!)
          TestSubscriber.subscribe!
        else
          TestSubscriber.activate
        end
      end
    else
      let(:event_type_class) { Omnes::UnstructuredEvent }

      before { TestSubscriber.omnes_subscriber.subscribe_to(Spree::Bus) }
    end

    it 'fires the order_recalculated event exactly once' do
      allow(TestSubscriber).to receive(:order_recalculated)

      subject

      expect(TestSubscriber).to have_received(:order_recalculated)
        .with(instance_of(event_type_class))
        .once do |event|
          expect(event.payload[:order]).to eq(order)
        end
    end
  end
end
