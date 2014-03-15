class LostOffers < ActionMailer::Base
  default from: "1k@inov.by"

  def send offers, bot
    @offers = offers
    mail(to: bot.notification_email, subject: bot.name)
  end
end
