$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'amaranth'

RSpec.configure do |config|
  config.mock_with(:rspec) { |c| c.syntax = :should }
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

