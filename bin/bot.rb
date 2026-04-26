# frozen_string_literal: true

require "telegram/bot"
require "dotenv/load"
require_relative "../lib/blackjack"

TOKEN = ENV['TELEGRAM_BOT_TOKEN']

@sessions = {}

MAIN_MENU = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
  keyboard: [
    [{ text: 'Новая игра' }, { text: 'Сменить стратегию' }]
  ],
  resize_keyboard: true
)

puts "Бот запущен..."

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      bot.api.answer_callback_query(callback_query_id: message.id)

      chat_id = message.message.chat.id
      game = @sessions[chat_id]

      next if game.nil?

      case message.data
      when /^set_strat_(\d+)$/
        threshold = $1.to_i

        game.dealer_strategy = Blackjack::DealerStrategy.new(threshold)

        strat_name = case threshold
                     when 15 then "Осторожная"
                     when 19 then "Рискованная"
                     else "Стандартная"
                     end

        bot.api.send_message(
          chat_id: chat_id,
          text: "✅ Установлена **#{strat_name}** стратегия дилера.\nВведите сумму ставки.",
          parse_mode: 'Markdown'
        )

      when 'hit'
        status = game.hit

        if status == :continue
          kb = [
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Взять ещё', callback_data: 'hit'),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хватит', callback_data: 'stand')
          ]
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [kb])

          bot.api.send_message(
            chat_id: chat_id,
            text: "Вы взяли карту.\n#{game.render_hand(game.player_hand)}",
            reply_markup: markup
          )
        else
          res = game.determine_winner
          bot.api.send_message(
            chat_id: chat_id,
            text: "#{status == :bust ? 'Перебор!' : '21!'} \n#{game.render_hand(game.player_hand)}\n\n" \
              "Дилер: #{game.render_hand(game.dealer_hand)}\n" \
              "ИТОГ: #{res[:message]}\nБаланс: $#{res[:bankroll]}",
            reply_markup: MAIN_MENU
          )
        end

      when 'stand'
        res = game.stand
        bot.api.send_message(
          chat_id: chat_id,
          text: "Вы остановились.\n#{game.render_hand(game.player_hand)}\n\n" \
            "Дилер: #{game.render_hand(game.dealer_hand)}\n" \
            "ИТОГ: #{res[:message]}\nБаланс: $#{res[:bankroll]}",
          reply_markup: MAIN_MENU
        )
      end

    when Telegram::Bot::Types::Message
      chat_id = message.chat.id

      case message.text
      when '/start', 'Новая игра'
        old_game = @sessions[chat_id]

        remove_markup = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

        if old_game
          @sessions[chat_id] = Blackjack::Game.new(old_game.bankroll, old_game.dealer_strategy)

          bot.api.send_message(
            chat_id: chat_id,
            text: "Новая раздача. \nВаш баланс: $#{@sessions[chat_id].bankroll}.\nНапишите сумму ставки.",
            reply_markup: remove_markup
          )
        else
          @sessions[chat_id] = Blackjack::Game.new

          bot.api.send_message(
            chat_id: chat_id,
            text: "Добро пожаловать в Блэкджек! \nВаш баланс: $#{@sessions[chat_id].bankroll}.\nНапишите сумму ставки (число), чтобы начать игру.",
            reply_markup: remove_markup
          )
        end

      when 'Сменить стратегию'
        @sessions[chat_id] ||= Blackjack::Game.new

        kb = [
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Осторожная', callback_data: 'set_strat_15')],
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Стандартная', callback_data: 'set_strat_17')],
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Рискованная', callback_data: 'set_strat_19')]
        ]
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

        bot.api.send_message(
          chat_id: chat_id,
          text: "Выберите стиль игры дилера:",
          reply_markup: markup
        )

      when /(\d+)/
        amount = $1.to_i
        game = @sessions[chat_id]

        if game.nil?
          bot.api.send_message(chat_id: chat_id, text: "Сначала напишите /start")
        elsif game.place_bet(amount)
          data = game.start_deal

          kb = [
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Взять ещё', callback_data: 'hit'),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хватит', callback_data: 'stand')
          ]
          remove_markup = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

          bot.api.send_message(
            chat_id: chat_id,
            text: "Ставка принята! Дилер раздал карты.",
            reply_markup: remove_markup
          )

          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [kb])
          bot.api.send_message(
            chat_id: chat_id,
            text: "Карта дилера: #{data[:dealer_visible_card]}\n" \
              "Ваши: #{game.render_hand(game.player_hand)}\n\n" \
              "Ваш ход:",
            reply_markup: markup
          )
        else
          bot.api.send_message(chat_id: chat_id, text: "Ошибка: ставка должна быть не больше $#{game.bankroll}")
        end

      else
        bot.api.send_message(chat_id: chat_id, text: "Напишите /start или сумму ставки (числом)")
      end
    end
  end
end