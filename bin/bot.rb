# frozen_string_literal: true

require "telegram/bot"
require_relative "../lib/blackjack"

TOKEN = ENV['TELEGRAM_BOT_TOKEN']

@sessions = {}

puts "Бот запущен..."

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|

  end
end