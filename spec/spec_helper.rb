# frozen_string_literal: true

require "pundit"
require "graphiti"
require "graphiti/pundit"
require "graphiti_spec_helpers/rspec"
require "active_support/isolated_execution_state"

# load fixtures
Dir[File.dirname(__FILE__) + "/fixtures/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include GraphitiSpecHelpers::RSpec
  config.include GraphitiSpecHelpers::Sugar

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
