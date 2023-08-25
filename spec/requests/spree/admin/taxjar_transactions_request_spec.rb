require "spec_helper"

RSpec.describe Spree::Admin::TaxjarTransactionsController, type: :request do
  extend Spree::TestingSupport::AuthorizationHelpers::Request

  stub_authorization!

  let(:dummy_taxjar_client) {
    instance_double Taxjar::Client,
      nexus_regions: "fake-value"
  }
  let(:order) { with_events_disabled { create :shipped_order } }

  before do
    create :taxjar_configuration,
      preferred_reporting_enabled_at_integer: 1.hour.ago

    allow(SuperGood::SolidusTaxjar::Api)
      .to receive(:default_taxjar_client)
      .and_return(dummy_taxjar_client)
  end

  describe "POST #retry" do
    subject { post "/admin/orders/#{order.number}/taxjar_transaction/retry" }

    context "when the order has TaxJar order transactions" do
      before do
        order.taxjar_order_transactions << create(
          :taxjar_order_transaction,
          order: order,
          transaction_id: order.number
        )
      end

      let(:dummy_taxjar_order) { instance_double ::Taxjar::Order }

      it "replaces the latest order transaction" do
        allow(::SuperGood::SolidusTaxjar.api)
          .to receive(:show_latest_transaction_for)
          .with(order)
          .once

        allow(dummy_taxjar_client)
          .to receive(:show_order)
          .with(order.taxjar_order_transactions.first.transaction_id)
          .and_return(instance_double ::Taxjar::Order, amount: "fake-amount")

        expect { subject }
          .to have_enqueued_job(SuperGood::SolidusTaxjar::ReplaceTransactionJob)
          .once
      end
    end

    context "when the order does not have TaxJar order transactions" do
      it "reports the initial order transaction" do
        expect { subject }
          .to have_enqueued_job(SuperGood::SolidusTaxjar::ReportTransactionJob)
          .once
      end
    end
  end
end
