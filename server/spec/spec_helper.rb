# frozen_string_literal: true

require "rack/test"
require_relative "../lib/fhirpath_server"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
