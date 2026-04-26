# frozen_string_literal: true

require_relative "test_helper"
require "ostruct"
require_relative "../bin/bot.rb"

class BotTest < Minitest::Test
  class MockApi
    attr_reader :sent_messages, :answered_callbacks

    def initialize
      @sent_messages = []
      @answered_callbacks = []
    end

    def send_message(**params)
      @sent_messages << params
    end

    def answer_callback_query(**params)
      @answered_callbacks << params
    end
  end

  def setup
    @bot_app = BlackjackBot.new("fake_token")

    @api = MockApi.new
    mock_telegram_bot = OpenStruct.new(api: @api)

    @bot_app.instance_variable_set(:@bot, mock_telegram_bot)

    @chat_id = 12345
  end

  def mock_message(text)
    OpenStruct.new(
      chat: OpenStruct.new(id: @chat_id),
      text: text
    )
  end

  def mock_callback(data)
    OpenStruct.new(
      id: "cb_1",
      message: mock_message(nil),
      data: data
    )
  end


  def test_start_command_creates_new_session
    @bot_app.send(:route_message, mock_message("/start"))

    sessions = @bot_app.instance_variable_get(:@sessions)
    assert sessions.key?(@chat_id), "Сессия для chat_id должна быть создана"
    assert_instance_of Blackjack::Game, sessions[@chat_id]

    last_message = @api.sent_messages.last
    assert_equal @chat_id, last_message[:chat_id]
    assert_match(/Добро пожаловать в Блэкджек/, last_message[:text])
  end

  def test_place_bet_without_start_prompts_to_start
    @bot_app.send(:route_message, mock_message("50"))

    last_message = @api.sent_messages.last
    assert_match(/Сначала напишите \/start/, last_message[:text])
  end

  def test_valid_bet_starts_the_deal
    @bot_app.send(:route_message, mock_message("/start"))
    @api.sent_messages.clear

    @bot_app.send(:route_message, mock_message("100"))

    game = @bot_app.instance_variable_get(:@sessions)[@chat_id]

    assert_equal 100, game.current_bet
    assert_equal 2, game.player_hand.cards.size

    assert_equal 2, @api.sent_messages.size
    assert_match(/Ставка принята/, @api.sent_messages.first[:text])
    assert_match(/Карта дилера:.*Ваши:.*Ваш ход:/m, @api.sent_messages.last[:text])
  end

  def test_invalid_bet_shows_error
    @bot_app.send(:route_message, mock_message("/start"))

    @bot_app.send(:route_message, mock_message("5000"))

    last_message = @api.sent_messages.last
    assert_match(/Ошибка: ставка должна быть не больше/, last_message[:text])
  end

  def test_hit_callback_adds_card_to_player
    @bot_app.send(:route_message, mock_message("/start"))
    @bot_app.send(:route_message, mock_message("10"))

    game = @bot_app.instance_variable_get(:@sessions)[@chat_id]
    initial_cards_count = game.player_hand.cards.size

    @api.sent_messages.clear

    @bot_app.send(:route_message, mock_callback("hit"))

    assert_equal 1, @api.answered_callbacks.size

    last_message = @api.sent_messages.last

    possible_outcomes = ["Вы взяли карту", "Перебор!", "21!"]
    assert possible_outcomes.any? { |outcome| last_message[:text].include?(outcome) }

    assert_operator game.player_hand.cards.size, :>, initial_cards_count
  end

  def test_stand_callback_finishes_game
    @bot_app.send(:route_message, mock_message("/start"))
    @bot_app.send(:route_message, mock_message("10"))
    @api.sent_messages.clear

    @bot_app.send(:route_message, mock_callback("stand"))

    last_message = @api.sent_messages.last

    assert_match(/Вы остановились.*ИТОГ.*Баланс:/m, last_message[:text])

    assert_equal BlackjackBot::MAIN_MENU, last_message[:reply_markup]
  end

  def test_change_strategy_callback
    @bot_app.send(:route_message, mock_message("/start"))
    @api.sent_messages.clear

    @bot_app.send(:route_message, mock_callback("set_strat_19"))

    game = @bot_app.instance_variable_get(:@sessions)[@chat_id]

    assert_equal 19, game.dealer_strategy.stop_threshold

    last_message = @api.sent_messages.last
    assert_match(/Установлена.*рискованная.*стратегия/i, last_message[:text])
  end
end