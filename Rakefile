# frozen_string_literal: true

require "bundler/gem_tasks"
require 'solidus_dev_support/rake_tasks'
SolidusDevSupport::RakeTasks.install

ENV['LIB_NAME'] = "super_good/solidus_taxjar"

namespace :extension do
  desc "Installs the Solidus storefront into the dummy app"
  task :storefront do
    dummy_path = Pathname(ENV.fetch("DUMMY_PATH", "spec/dummy")).expand_path

    gemfile = dummy_path.join("Gemfile")
    gemfile.write("# Unused. See the Gemfile in the extension root.\n")
    dummy_path.join("public/robots.txt").write("")

    template = Spree::Core::Engine.root
      .join("lib/generators/solidus/install/app_templates/frontend/starter.rb")

    begin
      Dir.chdir(dummy_path) do
        sh "bin/rails", "importmap:install", "turbo:install", "stimulus:install"

        # Without AUTO_ACCEPT the template prompts before overwriting the
        # JavaScript installed above, and hangs.
        sh({"AUTO_ACCEPT" => "1"}, "bin/rails", "app:template", "LOCATION=#{template}")
      end
    ensure
      gemfile.delete
    end

    # Sass can't parse the CSS Tailwind builds. The template sets this too, but
    # anchors the insertion on a line the dummy app doesn't have.
    test_environment = dummy_path.join("config/environments/test.rb")
    test_environment.write(
      test_environment.read.sub(/^end\b/, "  config.assets.css_compressor = nil\nend")
    )

    rm_rf dummy_path.join("spec")
    rm_f dummy_path.join(".rspec")
    rm_rf Dir[dummy_path.join("tmp/solidus_starter_frontend-*")]

    # Up to Solidus v4.7 the storefront renders before asking `fresh_when`,
    # which Rails 8.1 rejects as a double render. Drop once that fix ships.
    store_controller = dummy_path.join("app/controllers/store_controller.rb")
    store_controller.write(store_controller.read.sub(
      "    render partial: 'shared/cart/link_to_cart'\n" \
      "    fresh_when(etag: current_order, template: 'shared/cart/_link_to_cart')\n",
      "    unless fresh_when(etag: current_order, template: 'shared/cart/_link_to_cart')\n" \
      "      render partial: 'shared/cart/link_to_cart'\n" \
      "    end\n"
    ))
  end
end

Rake::Task["extension:test_app"].enhance { Rake::Task["extension:storefront"].invoke }

task default: 'extension:specs'
