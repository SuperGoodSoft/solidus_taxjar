# frozen_string_literal: true

RSpec.describe SuperGood::SolidusTaxjar::ReportingSubscriber do
  describe 'order_finalized' do
    context 'when the order is taxable' do
      it 'creates a transaction in TaxJar asynchronously' do
        order = create(:order)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { true })

        Spree::Event.fire 'order_finalized', order: order

        expect(SuperGood::SolidusTaxjar::CreateOrderJob).to have_been_enqueued.with(order)
      end
    end

    context 'when the order is not taxable' do
      it 'does not create a transaction in TaxJar' do
        order = create(:order)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { false })

        Spree::Event.fire 'order_finalized', order: order

        expect(SuperGood::SolidusTaxjar::CreateOrderJob).not_to have_been_enqueued
      end
    end
  end

  describe 'order_recalculated' do
    context 'when the order is finalized and taxable' do
      it "updates the order's transaction in TaxJar asynchronously" do
        order = create(:completed_order_with_totals)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { true })

        Spree::Event.fire 'order_recalculated', order: order

        expect(SuperGood::SolidusTaxjar::UpdateOrderJob).to have_been_enqueued.with(order)
      end
    end

    context 'when the order is not finalized but taxable' do
      it 'does not create a transaction in TaxJar' do
        order = create(:order)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { true })

        Spree::Event.fire 'order_recalculated', order: order

        expect(SuperGood::SolidusTaxjar::UpdateOrderJob).not_to have_been_enqueued
      end
    end

    context 'when the order is finalized but not taxable' do
      it 'does not create a transaction in TaxJar' do
        order = create(:completed_order_with_totals)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { false })

        Spree::Event.fire 'order_recalculated', order: order

        expect(SuperGood::SolidusTaxjar::UpdateOrderJob).not_to have_been_enqueued
      end
    end
  end

  describe 'reimbursement_reimbursed' do
    context 'when the order is taxable' do
      it 'creates a refund in TaxJar asynchronously' do
        reimbursement = create(:reimbursement)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { true })

        Spree::Event.fire 'reimbursement_reimbursed', reimbursement: reimbursement

        expect(SuperGood::SolidusTaxjar::CreateRefundJob).to have_been_enqueued.with(reimbursement)
      end
    end

    context 'when the order is not taxable' do
      it 'does not create a refund in TaxJar' do
        reimbursement = create(:reimbursement)
        allow(SuperGood::SolidusTaxJar).to receive(:taxable_order_check).and_return(-> (_) { false })

        Spree::Event.fire 'reimbursement_reimbursed', reimbursement: reimbursement

        expect(SuperGood::SolidusTaxjar::CreateRefundJob).not_to have_been_enqueued
      end
    end
  end
end
