require 'spec_helper'

RSpec.describe Spree::Admin::OrdersController, :type => :request do
  include Capybara::RSpecMatchers

  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!

  describe "#edit" do
    subject { get spree.edit_admin_order_path(order) }

    let!(:order) { create(:shipped_order) }

    before do
      allow(SuperGood::SolidusTaxjar).to receive(:reporting_ui_enabled).and_return(true)
    end

    it "displays an empty value for the TaxJar reported at time" do
      subject
      expect(response.body).to have_text("Reported to TaxJar at: -", normalize_ws: true)
    end

    context "if the order has reported transactions" do
      before do
        create :transaction_sync_log, :success, order: order, created_at: DateTime.new(2022,01,01,12,12)
        create :transaction_sync_log, :success, order: order, created_at: DateTime.new(2022,06,06,12,12)
      end

      it "displays the date and time of the most recent transaction sync" do
        subject
        expect(response.body).to have_text("Reported to TaxJar at: June 06, 2022 12:12 PM", normalize_ws: true)
      end
    end

    context "when the reporting UI is disabled" do
      before do
        allow(SuperGood::SolidusTaxjar).to receive(:reporting_ui_enabled).and_return(false)
      end

      it "does not show the reported at time" do
        subject
        expect(response.body).not_to have_text("Reported to TaxJar at")
      end
    end
  end
end
