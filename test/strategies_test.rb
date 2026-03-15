# frozen_string_literal: true

require_relative "test_helper"

class StrategiesTest < Minitest::Test
  MockHand = Struct.new(:value)

  def test_base_strategy_raises_error
    strategy = Blackjack::BaseStrategy.new
    hand = MockHand.new(15)

    assert_raises(NotImplementedError) do
      strategy.should_hit?(hand)
    end
  end

  def test_standard_strategy_logic
    strategy = Blackjack::StandardStrategy.new

    assert strategy.should_hit?(MockHand.new(16))
    assert strategy.should_hit?(MockHand.new(17))

    refute strategy.should_hit?(MockHand.new(18))
  end

  def test_cautious_strategy_logic
    strategy = Blackjack::CautiousStrategy.new

    assert strategy.should_hit?(MockHand.new(14))

    refute strategy.should_hit?(MockHand.new(15))
    refute strategy.should_hit?(MockHand.new(16))
  end

  def test_risky_strategy_logic
    strategy = Blackjack::RiskyStrategy.new

    assert strategy.should_hit?(MockHand.new(18))

    refute strategy.should_hit?(MockHand.new(19))
    refute strategy.should_hit?(MockHand.new(20))
  end
end