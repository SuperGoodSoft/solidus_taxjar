# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :taxjar_settings, only: [:show]
  end
end
