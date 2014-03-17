class BotsLauncher
  def self.launch_all_bots
    Bot.all.each do |bot|
      CrawlerWorker.perform_async(bot.id)
    end
  end
end
