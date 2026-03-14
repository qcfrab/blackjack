# frozen_string_literal: true

require_relative 'card'

module Blackjack
  class Hand
    attr_reader :cards

    def initialize
      @cards = []
    end

    def add_card(card)
      @cards << card
    end

    def value
      total = @cards.sum { |card| card.value }

      aces_count = @cards.count { |card| card.ace? }

      while total > 21 && aces_count > 0
        total -= 10
        aces_count -= 1
      end

      total
    end

    def to_s
      @cards.join(', ')
    end
  end
end