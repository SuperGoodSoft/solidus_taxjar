require 'spec_helper'

RSpec.describe Spree::Admin::OrdersController, :type => :request do
  include Capybara::RSpecMatchers

  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!

  describe "#edit" do
    subject { get spree.edit_admin_order_path(order) }

    let!(:order) { create(:shipped_order) }
    let(:reporting_enabled_at) { 1.day.ago.to_i }

    around do |example|
      begin
        old_value = SuperGood::SolidusTaxjar
          .configuration
          .preferred_reporting_enabled_at_integer
        SuperGood::SolidusTaxjar.configuration.update!(
          preferred_reporting_enabled_at_integer: reporting_enabled_at
        )
        example.run
      ensure
        SuperGood::SolidusTaxjar.configuration.update!(
          preferred_reporting_enabled_at_integer: old_value
        )
      end
    end

    it "displays an empty value for the TaxJar reported at time" do
      subject
      expect(response.body).to have_text("Reported to TaxJar at: -", normalize_ws: true)
    end

    it "displays a 'pending' status" do
      subject
      expect(response.body).to have_text("TaxJar Sync: Pending", normalize_ws: true)
    end

    it "displays a link to view the TaxJar Sync History" do
      subject
      expect(response.body).to have_link("TaxJar Sync History", href: spree.taxjar_transactions_admin_order_path(order))
    end

    context "if the order has reported transactions" do
      let(:latest_sync_log_status) { :success }

      before do
        create :transaction_sync_log, :success, order: order, created_at: DateTime.new(2022,01,01,12,12)
        create(
          :transaction_sync_log,
          order: order,
          created_at: DateTime.new(2022,06,06,12,12),
          order_transaction: create(:taxjar_order_transaction, order: order),
          status: latest_sync_log_status
        )
      end

      it "displays the date and time of the most recent transaction sync" do
        subject
        expect(response.body).to have_text("Reported to TaxJar at: June 06, 2022 12:12 PM", normalize_ws: true)
      end

      it "displays the status of the transaction sync log" do
        subject
        expect(response.body).to have_text("TaxJar Sync: #{latest_sync_log_status.capitalize}", normalize_ws: true)
      end
    end

    context "when transaction syncing is turned off" do
      let(:reporting_enabled_at) { nil }

      it "displays a 'disabled' status" do
        subject
        expect(response.body).to have_text("TaxJar Sync: Disabled", normalize_ws: true)
      end

      context "and a transaction sync log exists" do
        let(:latest_sync_log_status) { :success }

        before do
          create(
            :transaction_sync_log,
            order: order,
            created_at: DateTime.new(2022,06,06,12,12),
            order_transaction: create(:taxjar_order_transaction, order: order),
            status: latest_sync_log_status
          )
        end

        it "displays the status of the transaction sync log" do
          subject
          expect(response.body).to have_text("TaxJar Sync: #{latest_sync_log_status.capitalize}", normalize_ws: true)
        end
      end
    end
  end

  describe "#taxjar_transactions" do
    subject { get spree.taxjar_transactions_admin_order_path(order) }

    let!(:order) { create(:shipped_order) }
    let(:order_transaction) { create :taxjar_order_transaction, transaction_id: "Test-123"}

    before do
      create :transaction_sync_log, order: order, order_transaction: order_transaction, status: :success
    end

    it "renders the taxjar transactions page for the order" do
      subject
      expect(response.body).to have_text(/TaxJar Sync History - #?#{order.number} - Orders/)
    end

    it "renders the transaction sync logs" do
      subject
      expect(response.body).to have_text("#{order.number} Test-123 Success", normalize_ws: true)
    end
  end
end
