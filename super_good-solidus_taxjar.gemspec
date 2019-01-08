lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "super_good/solidus_taxjar/version"

Gem::Specification.new do |spec|
  spec.name          = "super_good-solidus_taxjar"
  spec.version       = SuperGood::SolidusTaxJar::VERSION
  spec.authors       = ["Jared Norman"]
  spec.email         = ["jared@super.gd"]

  spec.summary       = "Support for using TaxJar to handle tax calculations in Solidus"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/SuperGoodSoft/solidus_taxjar"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "solidus_core", ">= 2.4.0"
  spec.add_dependency "solidus_support"
  spec.add_dependency "taxjar-ruby"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 4.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "database_cleaner"
end
