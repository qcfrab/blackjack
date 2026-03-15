# frozen_string_literal: true

module Blackjack
  class BaseStrategy
    def should_hit?(hand)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end
  end

  class StandardStrategy < BaseStrategy
    def should_hit?(hand)
      hand.value <= 17
    end
  end

  class CautiousStrategy < BaseStrategy
    def should_hit?(hand)
      hand.value < 15
    end
  end
  class RiskyStrategy < BaseStrategy
    def should_hit?(hand)
      hand.value < 19
    end
  end
end