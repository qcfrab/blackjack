# frozen_string_literal: true

require_relative 'card'

module Blackjack
  class Deck
    SUITS = %w[♠ ♣ ♥ ♦].freeze
    RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze

    attr_reader :cards

    def initialize
      @cards = []

      RANKS.each do |rank|
        SUITS.each do |suit|
          @cards << Card.new(rank, suit)
        end
      end

      @cards.shuffle!
    end

    def draw
      @cards.pop
    end

    def count
      @cards.size
    end
  end
end