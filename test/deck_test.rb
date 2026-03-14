# frozen_string_literal: true

require_relative "test_helper"

class DeckTest < Minitest::Test
  def test_deck_has_52_cards
    deck = Blackjack::Deck.new

    assert_equal 52, deck.count
  end

  def test_draw_removes_card_and_decreases_count
    deck = Blackjack::Deck.new

    initial_count = deck.count

    drawn_card = deck.draw

    assert_instance_of Blackjack::Card, drawn_card

    assert_equal initial_count - 1, deck.count
  end
end