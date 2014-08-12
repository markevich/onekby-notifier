class CrawlerWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(bot_id)
    Spider.start(bot_id)
  end
end
