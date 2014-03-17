class CrawlerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(bot_id)
    bot = Bot.find(bot_id)
    Crawler.start(bot)
  end
end
