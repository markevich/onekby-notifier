class LostOffers < ActionMailer::Base
  default from: "1k@inov.by"

  def lost_offers offers, bot
    @offers = offers
    mail(to: bot.notification_email, subject: bot.name)
  end
end
