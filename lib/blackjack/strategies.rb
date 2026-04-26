module Blackjack
  class DealerStrategy
    attr_reader :stop_threshold

    def initialize(stop_threshold = 17)
      @stop_threshold = stop_threshold
    end

    def should_hit?(hand)
      hand.value < @stop_threshold
    end
  end
end