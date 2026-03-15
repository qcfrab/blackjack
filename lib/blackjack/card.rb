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

    def render
      color = (suit == '♥' || suit == '♦') ? "\e[31m" : "\e[37m"
      reset = "\e[0m"
      r = rank.ljust(2)

      [
        "┌─────────┐",
        "│ #{r}      │",
        "│         │",
        "│    #{color}#{suit}#{reset}    │",
        "│         │",
        "│       #{r}│",
        "└─────────┘"
      ]
    end
  end
end