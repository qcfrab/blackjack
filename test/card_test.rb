# frozen_string_literal: true

require_relative "test_helper"

class TestCard < Minitest::Test
  def test_initialize_sets_rank_and_suit
    card = Blackjack::Card.new('10', '♠')

    assert_equal '10', card.rank
    assert_equal '♠', card.suit
  end

  def test_to_s_returns_combined_string
    card = Blackjack::Card.new('K', '♥')

    assert_equal 'K♥', card.to_s
  end

  def test_value_returns_10_for_face_cards
    assert_equal 10, Blackjack::Card.new('J', '♦').value
    assert_equal 10, Blackjack::Card.new('Q', '♣').value
    assert_equal 10, Blackjack::Card.new('K', '♠').value
  end

  def test_value_returns_11_for_ace
    assert_equal 11, Blackjack::Card.new('A', '♥').value
  end

  def test_value_returns_integer_for_number_cards
    assert_equal 7, Blackjack::Card.new('7', '♣').value
    assert_equal 2, Blackjack::Card.new('2', '♦').value
    assert_equal 10, Blackjack::Card.new('10', '♠').value
  end

  def test_ace_returns_true_for_ace
    card = Blackjack::Card.new('A', '♠')

    assert card.ace?
  end

  def test_ace_returns_false_for_non_ace
    card = Blackjack::Card.new('8', '♥')

    refute card.ace?
  end
end