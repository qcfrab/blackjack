# frozen_string_literal: true

require_relative "test_helper"

class DealerStrategyTest < Minitest::Test
  MockHand = Struct.new(:value)

  def test_default_strategy_logic
    strategy = Blackjack::DealerStrategy.new

    assert strategy.should_hit?(MockHand.new(16)), "Дилер должен брать карту на 16"
    refute strategy.should_hit?(MockHand.new(17)), "Дилер должен остановиться на 17"
  end

  def test_cautious_logic
    strategy = Blackjack::DealerStrategy.new(15)

    assert strategy.should_hit?(MockHand.new(14))
    refute strategy.should_hit?(MockHand.new(15))
    refute strategy.should_hit?(MockHand.new(16))
  end

  def test_risky_logic
    strategy = Blackjack::DealerStrategy.new(19)

    assert strategy.should_hit?(MockHand.new(18))
    refute strategy.should_hit?(MockHand.new(19))
    refute strategy.should_hit?(MockHand.new(20))
  end

end