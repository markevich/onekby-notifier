require 'capybara/rails'
require 'capybara/poltergeist'
Capybara.register_driver :selenium_firebug do |app|
  require 'capybara/firebug'
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.enable_firebug
  Capybara::Selenium::Driver.new(app, :profile => profile)
end

Capybara.run_server = false
Capybara.app_host = 'http://1k.by'
Capybara.default_wait_time = 5

class Crawler
  def self.start(bot)
    new.start(bot)
  end

  def start(bot)
    @session = Capybara::Session.new(:poltergeist)

    auth(bot)
    visit_catalog
    promotions = get_promotions
    exclude_without_offers(promotions)
    offers = collect_offers(promotions)
    offers = sort(offers)
    LostOffers.lost_offers(offers, bot).deliver!
  end

  private

  def sort(offers)
    offers.sort_by {|o| o[:title]}
  end

  def collect_offers(promotions)
    promotions.each do |promotion|
      @session.visit(promotion[:inner_link])
      offers = deep_collect_offers(1)
      delete_inactive_or_winning(offers)
      promotion[:offers] = offers
    end
    promotions
  end

  def delete_inactive_or_winning(categories)
    categories.each do |category|
      category[:offers].delete_if do |offer|
        #1.0/1.0 (2)
        regexp = /\d+\.\d+\/\d+\.\d+\s\((.+)\)/
        match_data = offer[:position].match(regexp)

        return true unless match_data

        match_data[1].to_i <= 1
      end
    end
  end

  def deep_collect_offers(page_number)
    @session.has_css?('span.pages', text: page_number.to_s)
    table = @session.evaluate_script("$('table.fs-lrg').html()")
    doc = Nokogiri::HTML(table)
    rows = doc.xpath('//tbody/tr')
    offers = rows.collect do |row|
      offer = {}
      [
        [:title, 'td[1]'],
        [:position, 'td[2]'],
        [:bet, 'td[3]'],
      ].each do |name, xpath|
        offer[name] = row.at_xpath(xpath).text.strip
      end
      offer
    end
    offers = [{ page: page_number, offers: offers }]
    return offers unless @session.has_link?('Следующая')
    Rails.logger.info("Clicked #{page_number + 1} page")
    @session.click_link((page_number + 1).to_s)

    deep_offers = deep_collect_offers(page_number + 1).flatten
    offers.concat(deep_offers)
  end

  def exclude_without_offers(promotions)
    promotions.delete_if do |promotion|
      promotion[:offers_count].to_i == 0
    end
  end

  def visit_catalog
    @session.visit('/users/shops-productscategoriespromotion')
  end

  def auth(bot)
    @session.visit('/')

    if @session.mode == :selenium_firebug
      @session.driver.browser.manage.add_cookie(name: '__userid', value: bot.auth_user_id,
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')

      @session.driver.browser.manage.add_cookie(name: '__checksum', value: bot.auth_session_id,
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')
    elsif @session.mode == :poltergeist
      @session.driver.set_cookie('__userid', bot.auth_user_id,
                                 expires: (Time.now + 1.month))

      @session.driver.set_cookie('__checksum', bot.auth_session_id,
                                 expires: (Time.now + 1.month))

    end

    @session.visit('/')
  end

  def get_promotions
    table = @session.evaluate_script("$('table.fs-lrg').html()")
    doc = Nokogiri::HTML(table)
    rows = doc.xpath('//tbody/tr')
    details = rows.collect do |row|
      detail = {}
      [
        [:title, 'td[1]'],
        [:offers_count, 'td[2]'],
        [:inner_link, 'td[2]/a/@href'],
        [:position, 'td[3]'],
        [:bet, 'td[4]']
      ].each do |name, xpath|
        value = row.at_xpath(xpath)
        value = value.text.strip unless value.nil?
        detail[name] = value
      end
      detail
    end
    details
  end
end
