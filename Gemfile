# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in auctify.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gem "folio", github: "sinfin/folio", branch: "master"
# gem "folio", path: "../folio"

# To use a debugger
# gem 'byebug', group: [:development, :test]

# for dummy app
gem "yabeda-rails"
gem "yabeda-prometheus"
gem "yabeda-sidekiq"
gem "yabeda-puma-plugin"
