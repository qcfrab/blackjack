# frozen_string_literal: true

require "telegram/bot"
require "dotenv/load"
require_relative "../lib/blackjack"

TOKEN = ENV['TELEGRAM_BOT_TOKEN']

@sessions = {}

puts "Бот запущен..."

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      bot.api.answer_callback_query(callback_query_id: message.id)

      chat_id = message.message.chat.id
      game = @sessions[chat_id]

      next if game.nil?

      start_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: [[ { text: '/start' } ]],
        resize_keyboard: true,
        one_time_keyboard: true
      )

      case message.data
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
            reply_markup: start_markup
          )
        end

      when 'stand'
        res = game.stand
        bot.api.send_message(
          chat_id: chat_id,
          text: "Вы остановились.\n#{game.render_hand(game.player_hand)}\n\n" \
            "Дилер: #{game.render_hand(game.dealer_hand)}\n" \
            "ИТОГ: #{res[:message]}\nБаланс: $#{res[:bankroll]}",
          reply_markup: start_markup
        )
      end

    when Telegram::Bot::Types::Message
      chat_id = message.chat.id

      case message.text
      when '/start'
        old_game = @sessions[chat_id]

        if old_game
          saved_bankroll = old_game.bankroll

          @sessions[chat_id] = Blackjack::Game.new(saved_bankroll)

          bot.api.send_message(
            chat_id: chat_id,
            text: "Новая раздача. \nТвой баланс: $#{@sessions[chat_id].bankroll}.\nНапиши сумму ставки."
          )
        else
          @sessions[chat_id] = Blackjack::Game.new

          bot.api.send_message(
            chat_id: chat_id,
            text: "Добро пожаловать в Блэкджек! \nТвой баланс: $#{@sessions[chat_id].bankroll}.\nНапиши сумму ставки (число), чтобы начать игру."
          )
        end

      when /(\d+)/
        amount = $1.to_i
        game = @sessions[chat_id]

        if game.nil?
          bot.api.send_message(chat_id: chat_id, text: "Сначала напиши /start")
        elsif game.place_bet(amount)
          data = game.start_deal

          kb = [
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Взять ещё', callback_data: 'hit'),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Хватит', callback_data: 'stand')
          ]
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [kb])

          bot.api.send_message(
            chat_id: chat_id,
            text: "Ставка принята! Дилер раздал карты.\n\n" \
              "Карта дилера: #{data[:dealer_visible_card]}\n" \
              "Ваши: #{game.render_hand(game.player_hand)}\n\n" \
              "Ваш ход:",
            reply_markup: markup
          )
        else
          bot.api.send_message(chat_id: chat_id, text: "Ошибка: ставка должна быть не больше $#{game.bankroll}")
        end

      else
        bot.api.send_message(chat_id: chat_id, text: "Напиши /start или сумму ставки (числом)")
      end
    end
  end
end