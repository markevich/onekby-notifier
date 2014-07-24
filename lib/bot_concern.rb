module BotConcern
  extend ActiveSupport::Concern

  require 'capybara/rails'
  require 'capybara/poltergeist'
  require 'capybara/firebug'

  included do
    Capybara.register_driver :selenium_firebug do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.enable_firebug
      Capybara::Selenium::Driver.new(app, :profile => profile)
    end

    Capybara.run_server = false
    Capybara.app_host = 'http://1k.by'
    Capybara.default_wait_time = 5
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

    else
      @session.driver.browser.manage.add_cookie(name: '__userid', value: bot.auth_user_id,
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')

      @session.driver.browser.manage.add_cookie(name: '__checksum', value: bot.auth_session_id,
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')
    end

    @session.visit('/')
  end

  def visit_catalog
    @session.visit('/users/shops-productscategoriespromotion')
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

  def get_categories
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
    details.delete_if do |promotion|
      promotion[:offers_count].to_i == 0
    end
    details
  end
end
