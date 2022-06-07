# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "auctify/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "auctify"
  spec.version     = Auctify::VERSION
  spec.authors     = ["foton"]
  spec.email       = ["foton@centrum.cz"]
  spec.homepage    = "https://github.com/sinfin/auctify"
  spec.summary     = "Gem for adding auction behavior to models."
  spec.description = ""
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "http://rubygems.org"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4"
  spec.add_dependency "aasm", "~> 5.1.1"
  spec.add_dependency "fast_jsonapi"
  spec.add_dependency "with_advisory_lock"
  spec.add_dependency "yabeda-prometheus"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry-rails"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "guard-slimlint"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rails_config"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "annotate"
  spec.add_development_dependency "capybara"
  # system tests
  spec.add_development_dependency "puma"
  spec.add_development_dependency "selenium"
  spec.add_development_dependency "selenium-webdriver", "~> 3.142.7"
  spec.add_development_dependency "webdrivers"
end
