module Spree
  module Admin
    module OrdersControllerOverride
      # FIXME: Move this to TaxJar transactions controller.
      def taxjar_transactions
        load_order
      end

      Spree::Admin::OrdersController.prepend self
    end
  end
end
