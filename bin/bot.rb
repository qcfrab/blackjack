# frozen_string_literal: true

require "telegram/bot"
require "dotenv/load"
require_relative "../lib/blackjack"

class BlackjackBot
  MAIN_MENU = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
    keyboard: [
      [{ text: 'Новая игра' }, { text: 'Сменить стратегию' }]
    ],
    resize_keyboard: true
  ).freeze

  REMOVE_MARKUP = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true).freeze

  def initialize(token)
    @token = token
    @sessions = {}
  end

  def start
    puts "Бот запущен..."

    Telegram::Bot::Client.run(@token) do |bot|
      @bot = bot
      bot.listen { |message| route_message(message) }
    end
  end

  private

  def route_message(message)
    if message.respond_to?(:data) && !message.data.nil?
      handle_callback(message)
    elsif message.respond_to?(:text)
      handle_text(message)
    end
  end

  def handle_callback(callback)
    @bot.api.answer_callback_query(callback_query_id: callback.id)

    chat_id = callback.message.chat.id
    game = @sessions[chat_id]

    return unless game

    case callback.data
    when /^set_strat_(\d+)$/
      change_dealer_strategy(chat_id, game, Regexp.last_match(1).to_i)
    when 'hit'
      process_hit(chat_id, game)
    when 'stand'
      process_stand(chat_id, game)
    end
  end

  def handle_text(message)
    chat_id = message.chat.id
    text = message.text

    case text
    when '/start', 'Новая игра'
      start_new_game(chat_id)
    when 'Сменить стратегию'
      show_strategy_menu(chat_id)
    when /(\d+)/
      amount = Regexp.last_match(1).to_i
      place_bet(chat_id, amount)
    else
      send_message(chat_id, "Напишите /start или сумму ставки (числом).")
    end
  end

  def start_new_game(chat_id)
    old_game = @sessions[chat_id]

    if old_game
      @sessions[chat_id] = Blackjack::Game.new(old_game.bankroll, old_game.dealer_strategy)
      text = "Новая раздача. \nВаш баланс: $#{@sessions[chat_id].bankroll}.\nНапишите сумму ставки."
    else
      @sessions[chat_id] = Blackjack::Game.new
      text = "Добро пожаловать в Блэкджек! \nВаш баланс: $#{@sessions[chat_id].bankroll}.\nНапишите сумму ставки (число), чтобы начать игру."
    end

    send_message(chat_id, text, reply_markup: REMOVE_MARKUP)
  end

  def place_bet(chat_id, amount)
    game = @sessions[chat_id]

    return send_message(chat_id, "Сначала напишите /start") if game.nil?

    if game.place_bet(amount)
      data = game.start_deal
      send_message(chat_id, "Ставка принята! Дилер раздал карты.", reply_markup: REMOVE_MARKUP)

      text = "Карта дилера: #{data[:dealer_visible_card]}\n" \
        "Ваши: #{game.render_hand(game.player_hand)}\n\n" \
        "Ваш ход:"
      send_message(chat_id, text, reply_markup: hit_stand_keyboard)
    else
      send_message(chat_id, "Ошибка: ставка должна быть не больше $#{game.bankroll}")
    end
  end

  def process_hit(chat_id, game)
    status = game.hit

    if status == :continue
      text = "Вы взяли карту.\n#{game.render_hand(game.player_hand)}"
      send_message(chat_id, text, reply_markup: hit_stand_keyboard)
    else
      res = game.determine_winner
      header = status == :bust ? "Перебор!" : "21!"
      finish_round(chat_id, game, header, res)
    end
  end

  def process_stand(chat_id, game)
    res = game.stand
    finish_round(chat_id, game, "Вы остановились.", res)
  end

  def finish_round(chat_id, game, header_text, res)
    text = "#{header_text}\n#{game.render_hand(game.player_hand)}\n\n" \
      "Дилер: #{game.render_hand(game.dealer_hand)}\n" \
      "ИТОГ: #{res[:message]}\nБаланс: $#{res[:bankroll]}"

    send_message(chat_id, text, reply_markup: MAIN_MENU)
  end

  def change_dealer_strategy(chat_id, game, threshold)
    game.dealer_strategy = Blackjack::DealerStrategy.new(threshold)

    strat_name = case threshold
                 when 15 then "Осторожная"
                 when 19 then "Рискованная"
                 else "Стандартная"
                 end

    text = "Установлена **#{strat_name.downcase}** стратегия дилера.\nВведите сумму ставки."
    send_message(chat_id, text, parse_mode: 'Markdown')
  end

  def show_strategy_menu(chat_id)
    @sessions[chat_id] ||= Blackjack::Game.new

    kb = [
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Осторожная', callback_data: 'set_strat_15')],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Стандартная', callback_data: 'set_strat_17')],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Рискованная', callback_data: 'set_strat_19')]
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    send_message(chat_id, "Выберите стиль игры дилера:", reply_markup: markup)
  end

  def hit_stand_keyboard
    kb = [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Взять ещё', callback_data: 'hit'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хватит', callback_data: 'stand')
    ]
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [kb])
  end

  def send_message(chat_id, text, reply_markup: nil, parse_mode: nil)
    params = { chat_id: chat_id, text: text }
    params[:reply_markup] = reply_markup if reply_markup
    params[:parse_mode] = parse_mode if parse_mode

    @bot.api.send_message(**params)
  end
end

if __FILE__ == $PROGRAM_NAME
  token = ENV.fetch('TELEGRAM_BOT_TOKEN') { raise "Отсутствует TELEGRAM_BOT_TOKEN" }
  BlackjackBot.new(token).start
end