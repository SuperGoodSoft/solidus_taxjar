# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :taxjar_settings, only: [:edit, :update]
    get 'taxjar_settings/sync_nexus_regions', to: 'taxjar_settings#sync_nexus_regions'
  end
end
