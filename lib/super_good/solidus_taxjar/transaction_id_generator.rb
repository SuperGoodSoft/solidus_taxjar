module SuperGood
  module SolidusTaxjar
    # Responsible for generating `transaction_id` references for transactions
    # we create on TaxJar for Solidus orders. This class handles creating
    # associated ID's for transactions which need to be cancelled and recreated
    # when the order is updated in Solidus after it has been sent to the TaxJar
    # reporting API.
    class TransactionIdGenerator
      class << self
        # Generates the next sequential `transaction_id` given an order and
        # optionally the current transaction ID on TaxJar. This handles the
        # case where a transaction already has been created on TaxJar and later
        # needs to be cancelled and we need to create an updated transaction
        # with an associated identifier.
        #
        # @param order [Spree::Order] the order for which we want to generate a
        #   transaction ID.
        # @param current_transaction_id [String] the current transaction ID for
        #   the order if it exists on TaxJar.
        # @return [String] the next sequential `transaction_id`
        def next_transaction_id(order:, current_transaction_id: nil)
          if current_transaction_id.nil?
            "#{order.number}"
          elsif order.number == current_transaction_id
            "#{current_transaction_id}-1"
          else
            parts = current_transaction_id.rpartition("-")
            parts.last.next!
            parts.join
          end
        end

        # Generates a `transaction_id` for a refund transaction based on the
        # ID of the transaction we're refunding.
        #
        # @param transaction_id [String] the ID of the transaction we are
        #   refunding.
        # @return [String] the expected refund transaction ID.
        def refund_transaction_id(transaction_id)
          "#{transaction_id}-REFUND"
        end
      end
    end
  end
end
