# frozen_string_literal: true

require_relative "test_helper"

class HandTest < Minitest::Test
  def test_value_without_aces
    hand = Blackjack::Hand.new
    hand.add_card(Blackjack::Card.new('10', '♠'))
    hand.add_card(Blackjack::Card.new('7', '♦'))

    assert_equal 17, hand.value
  end

  def test_value_with_ace_as_eleven
    hand = Blackjack::Hand.new
    hand.add_card(Blackjack::Card.new('A', '♠'))
    hand.add_card(Blackjack::Card.new('9', '♦'))

    assert_equal 20, hand.value
  end

  def test_value_with_ace_as_one_to_avoid_bust
    hand = Blackjack::Hand.new
    hand.add_card(Blackjack::Card.new('A', '♠'))
    hand.add_card(Blackjack::Card.new('10', '♦'))
    hand.add_card(Blackjack::Card.new('5', '♣'))

    assert_equal 16, hand.value
  end

  def test_value_with_multiple_aces
    hand = Blackjack::Hand.new
    hand.add_card(Blackjack::Card.new('A', '♠'))
    hand.add_card(Blackjack::Card.new('A', '♦'))

    assert_equal 12, hand.value
  end
end