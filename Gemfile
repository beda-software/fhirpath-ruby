# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in fhirpath-rb.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.21"

group :development do
  # Only needed to (re)generate the ANTLR4 parser sources; not required by
  # consumers of a released gem, since the generated sources ship inside it.
  gem "antlr4-native", "~> 2.3"
end
