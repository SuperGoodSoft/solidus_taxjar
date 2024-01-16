# Set up some data that a store needs to work and be realistic.
#
RSpec.shared_context "checkoutable store" do
  let!(:default_store) { create :store, default: true }
  let!(:taxjar_configuration) {
    create :taxjar_configuration, :reporting_enabled
  }

  let!(:california) {
    create :state,
      country: create(:country, states_required: true),
      state_code: "CA"
  }

  let!(:check_payment_method) { create :check_payment_method }
  let!(:shipping_method) { create :shipping_method }
  let!(:stock_location) { create :stock_location }
  let!(:zone) { create :zone }
end
