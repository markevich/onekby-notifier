class LostOffers < ActionMailer::Base
  default from: "1k@inov.by"

  def lost_tech offers
    @offers = offers
    mail(to: ['slava.markevich@gmail.com', 'info@inov.by'], subject: 'Аукционы 1k.by')
  end

  def lost_tech offers
    @offers = offers
    mail(to: ['slava.markevich@gmail.com', 'inov@inov.by'], subject: 'Спорт 1k.by', template_name: 'lost_tech')
  end
end
