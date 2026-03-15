# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "blackjack"

require "minitest/autorun"

Dir[File.expand_path("*_test.rb", __dir__)].each do |file|
  require file
end