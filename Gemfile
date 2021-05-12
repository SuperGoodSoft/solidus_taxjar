source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')

gem "solidus", github: "solidusio/solidus", branch: branch

# Needed to help Bundler figure out how to resolve dependencies,
# otherwise it takes forever to resolve them.
# See https://github.com/bundler/bundler/issues/6677
gem "rails", ENV.fetch("RAILS_VERSION") { ">0.a" }

# Provides basic authentication functionality for testing parts of your engine
gem "solidus_auth_devise"
# ExecJS 2.8 has a bug in it which breaks js precompiling, which is required for our features
# specs. Many other solidus extensions are also experiencing failing specs because of this.
# For now, we should lock the version of ExecJS until a new release comes out that fixes this bug.
gem "execjs", '~> 2.7.0'

case ENV["DB"]
when "mysql"
  gem "mysql2"
when "postgresql"
  gem "pg"
else
  gem "sqlite3"
end

group :development, :test do
  gem "pry"
  gem "pry-stack_explorer"
  gem "pry-byebug"
end

gemspec

# Use a local Gemfile to include development dependencies that might not be
# relevant for the project or for other contributors, e.g. pry-byebug.
#
# We use `send` instead of calling `eval_gemfile` to work around an issue with
# how Dependabot parses projects: https://github.com/dependabot/dependabot-core/issues/1658.
send(:eval_gemfile, "Gemfile-local") if File.exist? "Gemfile-local"
