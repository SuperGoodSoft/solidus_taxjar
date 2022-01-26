source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

branch = ENV.fetch("SOLIDUS_BRANCH", "v3.1")

gem "solidus", github: "solidusio/solidus", branch: branch

# Provides basic authentication functionality for testing parts of your engine
gem "solidus_auth_devise"

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
