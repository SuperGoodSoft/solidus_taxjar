module SolidusEventsHelper
  # We can use this helper method to ensure that events are not run until after
  # the test setup has been completed. This helps us more easily test side
  # effects from events or control unintended side effects when attempting to
  # test functionality that is not event-driven but would otherwise emit events.
  #
  # @yield Any test setup you'd like to run without events being emitted.
  # @return The return value of the test setup in your block.
  def with_events_disabled(&block)
    if SolidusSupport::LegacyEventCompat.using_legacy?
      allow(Spree::Event).to receive(:fire).and_return(nil)
    else
      allow(Spree::Bus).to receive(:publish).and_return(nil)
    end

    object = yield block

    if SolidusSupport::LegacyEventCompat.using_legacy?
      allow(Spree::Event).to receive(:fire).and_call_original
    else
      allow(Spree::Bus).to receive(:publish).and_call_original
    end

    object
  end
end
