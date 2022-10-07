module Spree
  module Admin
    module OrdersControllerOverride
      def taxjar_transactions
        load_order
      end

      Spree::Admin::OrdersController.prepend self
    end
  end
end
