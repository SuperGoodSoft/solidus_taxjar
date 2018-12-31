source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem "solidus", github: "solidusio/solidus", branch: branch

if ENV.fetch('DB') == 'postgres'
  gem 'pg', '~> 0.21'
end

group :development, :test do
  gem "pry"
end

gemspec
