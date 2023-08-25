module Spree
  module Admin
    class TaxjarTransactionsController < Spree::Admin::BaseController
      include SuperGood::SolidusTaxjar::Reportable

      def retry
        order = Spree::Order.find_by number: params[:order_id]

        if transaction_replaceable? order
          replace_transaction order
          flash[:notice] = "Queued transaction sync job"
        elsif order_reportable? order
          report_transaction order
          flash[:notice] = "Queued transaction sync job"
        else
          flash[:error] = "Could not retry sync successfully"
        end

        redirect_to taxjar_transactions_admin_order_path(params[:order_id])
      end

      private

      def report_transaction(order)
        with_reportable(order) do
          SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order)
        end
      end

      def replace_transaction(order)
        with_replaceable(order) do
          SuperGood::SolidusTaxjar::ReplaceTransactionJob.perform_later(order)
        end
      end
    end
  end
end
