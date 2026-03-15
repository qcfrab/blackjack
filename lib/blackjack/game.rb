# frozen_string_literal: true

require_relative "deck"
require_relative "hand"
require_relative "strategies"

module Blackjack
  class Game
    attr_reader :player_hand, :dealer_hand, :deck

    def initialize
      @deck = Deck.new
      @player_hand = Hand.new
      @dealer_hand = Hand.new
      @dealer_strategy = StandardStrategy.new
      @bankroll = 1000
      @current_bet = 0
    end

    def start_deal
      @player_hand.add_card(@deck.draw)
      @player_hand.add_card(@deck.draw)

      first_dealer_card = @deck.draw
      @dealer_hand.add_card(first_dealer_card)
      puts "Открытая карта дилера:"
      puts first_dealer_card.render

      @dealer_hand.add_card(@deck.draw)
    end

    def player_turn
      loop do
        puts "\n" + "="*30
        puts "ВАШ ХОД"
        display_cards(@player_hand)
        puts "Очки: #{@player_hand.value}"
        puts "="*30

        if @player_hand.value >= 21
          puts "Перебор!" if @player_hand.value > 21
          break
        end

        print "Взять еще карту? (y/n): "
        choice = gets.chomp.downcase

        case choice
        when "y"
          @player_hand.add_card(@deck.draw)
        when "n"
          break
        else
          puts "Неверный ввод. Пожалуйста, введите 'y' или 'n'."
        end
      end
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

      puts "\n" + "=" * 20
      puts "ФИНАЛ: Вы (#{player_score}) | Дилер (#{dealer_score})"
      puts message
      puts "Ваш новый баланс: $#{@bankroll}"
      puts "=" * 20
    end

    def place_bet
      loop do
        puts "\nВаш баланс: $#{@bankroll}"
        print "Сделайте ставку: $"
        bet = gets.chomp.to_i

        if bet > 0 && bet <= @bankroll
          @current_bet = bet
          break
        else
          puts "Неверная ставка. Сумма должна быть больше нуля и не превышать ваш баланс."
        end
      end
    end

    def play
      puts "=== Настройка игры ==="
      puts "Выберите характер дилера:"
      puts "1 - Стандартный"
      puts "2 - Осторожный"
      puts "3 - Рисковый"
      print "Ваш выбор (1-3): "

      choice = gets.chomp

      selected_strategy = case choice
                          when "2"
                            Blackjack::CautiousStrategy.new
                          when "3"
                            Blackjack::RiskyStrategy.new
                          else
                            Blackjack::StandardStrategy.new
                          end

      @dealer_strategy = selected_strategy

      puts "=== Добро пожаловать в Блэкджек! ==="
      place_bet
      start_deal

      player_turn

      if @player_hand.value <= 21
        puts "\nХод дилера..."
        dealer_turn
      end

      determine_winner
    end

    private

    def display_cards(hand)
      rendered_cards = hand.cards.map { |card| card.render }

      7.times do |i|
        puts rendered_cards.map { |lines| lines[i] }.join(" ")
      end
    end
  end
end

if __FILE__ == $0
  game = Blackjack::Game.new
  game.play
end