# frozen_string_literal: true

require_relative "deck"
require_relative "hand"
require_relative "strategies"

module Blackjack
  class Game
    attr_reader :player_hand, :dealer_hand, :deck, :bankroll, :current_bet

    def initialize(starting_bankroll = 1000)
      @deck = Deck.new
      @player_hand = Hand.new
      @dealer_hand = Hand.new
      @dealer_strategy = StandardStrategy.new
      @bankroll = starting_bankroll
      @current_bet = 0
    end

    def set_strategy(choice)
      @dealer_strategy = case choice.to_s
                         when "2"
                           Blackjack::CautiousStrategy.new
                         when "3"
                           Blackjack::RiskyStrategy.new
                         else
                           Blackjack::StandardStrategy.new
                         end
    end

    def place_bet(amount)
      if amount > 0 && amount <= @bankroll
        @current_bet = amount
        true
      else
        false
      end
    end

    def start_deal
      @player_hand = Hand.new
      @dealer_hand = Hand.new

      @player_hand.add_card(@deck.draw)
      @player_hand.add_card(@deck.draw)

      first_dealer_card = @deck.draw
      @dealer_hand.add_card(first_dealer_card)
      @dealer_hand.add_card(@deck.draw)

      {
        player_score: @player_hand.value,
        dealer_visible_card: first_dealer_card
      }
    end

    def hit
      @player_hand.add_card(@deck.draw)

      if @player_hand.value > 21
        :bust
      elsif @player_hand.value == 21
        :blackjack
      else
        :continue
      end
    end

    def stand
      dealer_turn
      determine_winner
    end

    def dealer_turn
      while @dealer_hand.value < 21 && @dealer_strategy.should_hit?(@dealer_hand)
        @dealer_hand.add_card(@deck.draw)
      end
    end

    def determine_winner
      player_score = @player_hand.value
      dealer_score = @dealer_hand.value

      outcome = if player_score > 21
                  :loss
                elsif dealer_score > 21 || player_score > dealer_score
                  :win
                elsif player_score < dealer_score
                  :loss
                else
                  :push
                end

      results = {
        win:  [1,  "Вы выиграли!"],
        loss: [-1, "Дилер победил."],
        push: [0,  "Ничья. Ставка возвращена."]
      }

      modifier, message = results[outcome]

      @bankroll += (@current_bet * modifier)

      {
        player_score: player_score,
        dealer_score: dealer_score,
        message: message,
        bankroll: @bankroll,
        outcome: outcome
      }
    end

    def render_hand(hand)
      "#{hand.cards.map(&:to_s).join(' ')} (Очки: #{hand.value})"
    end

    def display_cards(hand)
      rendered_cards = hand.cards.map { |card| card.render }
      output = []

      7.times do |i|
        output << rendered_cards.map { |lines| lines[i] }.join(" ")
      end

      output.join("\n")
    end
  end
end