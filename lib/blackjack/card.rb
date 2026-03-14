# frozen_string_literal: true

module Blackjack
  class Card
    attr_reader :rank, :suit

    def initialize(rank, suit)
      @rank = rank
      @suit = suit
    end

    def to_s
      "#{rank}#{suit}"
    end

    def value
      case rank
        when 'J', 'Q', 'K' then 10
        when 'A'           then 11
        else rank.to_i
      end
    end

    def ace?
      rank == 'A'
    end
  end
end