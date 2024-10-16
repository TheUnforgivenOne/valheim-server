import 'dotenv/config';
import TelegramBot from 'node-telegram-bot-api';

const token = process.env.BOT_TOKEN;
const api = process.env.API;
const bot = new TelegramBot(token, { polling: true });

const COMMANDS = {
  start: '/start',
  run: '/run_valheim',
  stop: '/stop',
}

bot.on('message', async (msg) => {
  try {
    const chatId = msg.chat.id;
    const messageText = msg.text;

    if (messageText === COMMANDS.start) {
      await fetch(api + COMMANDS.start);
      await bot.sendMessage(chatId, 'Включаем ХРЮ-машину');
      return;
    }

    if (messageText === COMMANDS.run) {
      await fetch(api + COMMANDS.run);
      await bot.sendMessage(chatId, 'Включаем нашу ХРЮ-ландию, через 2 минуты ждем ХРЮ-чево');
      return;
    }

    if (messageText === COMMANDS.stop) {
      await fetch(api + COMMANDS.stop);
      await bot.sendMessage(chatId, 'Выключаем нашу ХРЮ-ландию, будем ХРЮ-чать ;(');
      return;
    }

    await bot.sendMessage(chatId, 'ХРЮ?');
    return;
  } catch (e) {
    return;
  }
});
