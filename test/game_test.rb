# frozen_string_literal: true

require_relative "test_helper"

class GameTest < Minitest::Test
  def setup
    @game = Blackjack::Game.new
  end

  def test_initialize_sets_default_values
    assert_equal 1000, @game.instance_variable_get(:@bankroll)
    assert_instance_of Blackjack::Deck, @game.deck
    assert_instance_of Blackjack::Hand, @game.player_hand
    assert_instance_of Blackjack::Hand, @game.dealer_hand
  end

  def test_start_deal_distributes_cards
    @game.stub :puts, nil do
      @game.start_deal
    end

    assert_equal 2, @game.player_hand.cards.count
    assert_equal 2, @game.dealer_hand.cards.count
    assert_equal 48, @game.deck.count
  end

  def test_determine_winner_player_wins
    @game.player_hand.add_card(Blackjack::Card.new('10', '♠'))
    @game.player_hand.add_card(Blackjack::Card.new('J', '♦'))

    @game.dealer_hand.add_card(Blackjack::Card.new('10', '♣'))
    @game.dealer_hand.add_card(Blackjack::Card.new('7', '♥'))

    @game.instance_variable_set(:@current_bet, 100)
    initial_bankroll = @game.instance_variable_get(:@bankroll)

    @game.stub :puts, nil do
      @game.determine_winner
    end

    assert_equal initial_bankroll + 100, @game.instance_variable_get(:@bankroll)
  end

  def test_determine_winner_player_busts
    @game.player_hand.add_card(Blackjack::Card.new('10', '♠'))
    @game.player_hand.add_card(Blackjack::Card.new('10', '♦'))
    @game.player_hand.add_card(Blackjack::Card.new('5', '♣'))

    @game.instance_variable_set(:@current_bet, 200)
    initial_bankroll = @game.instance_variable_get(:@bankroll)

    @game.stub :puts, nil do
      @game.determine_winner
    end

    assert_equal initial_bankroll - 200, @game.instance_variable_get(:@bankroll)
  end

  def test_place_bet_valid_input
    @game.stub :gets, "50\n" do
      @game.stub :print, nil do
        @game.stub :puts, nil do
          @game.place_bet(50)
        end
      end
    end

    assert_equal 50, @game.instance_variable_get(:@current_bet)
  end
end