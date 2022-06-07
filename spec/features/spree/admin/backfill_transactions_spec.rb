require 'spec_helper'

RSpec.feature 'Admin Transaction Sync Batches', js: true do
  stub_authorization!

  background do
    create :store, default: true
  end

  let!(:transaction_sync_batches) { create_list :transaction_sync_batch, 2, :with_logs }

  scenario "renders transaction backfill index" do
    visit spree.admin_transaction_sync_batches_path(per_page: 1)
    transaction_sync_batch = transaction_sync_batches.first
    within "#transaction_sync_batches" do
      expect(page).to have_content(transaction_sync_batch.id)
      expect(page).to have_content(transaction_sync_batch.created_at)
      expect(page).to have_content(transaction_sync_batch.updated_at)

      within "tbody td:nth-child(4)" do
        expect(page).to have_content("0/1")
      end

      within "tbody td:nth-child(5)" do
        expect(page).to have_content("Processing")
      end
    end

    within ".pagination" do
      click_on "Next"
    end

    second_transaction_sync_batch = transaction_sync_batches.second
    within "#transaction_sync_batches" do
      expect(page).to have_content(second_transaction_sync_batch.id)
      expect(page).to have_content(second_transaction_sync_batch.created_at)
      expect(page).to have_content(second_transaction_sync_batch.updated_at)

      within "tbody td:nth-child(4)" do
        expect(page).to have_content("0/1")
      end

      within "tbody td:nth-child(5)" do
        expect(page).to have_content("Processing")
      end
    end
  end
end
