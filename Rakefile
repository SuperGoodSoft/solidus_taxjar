# frozen_string_literal: true

require "bundler/gem_tasks"
require 'solidus_dev_support/rake_tasks'
SolidusDevSupport::RakeTasks.install

ENV['LIB_NAME'] = "super_good/solidus_taxjar"

task default: 'extension:specs'
