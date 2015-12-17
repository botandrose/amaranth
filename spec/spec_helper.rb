$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'amaranth'
require 'byebug'

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.mock_with(:rspec) { |c| c.syntax = :should }
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

