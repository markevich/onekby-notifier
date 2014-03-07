require 'capybara/rails'
require 'capybara/poltergeist'
Capybara.run_server = false
Capybara.app_host = 'http://1k.by'
Capybara.default_wait_time = 5

class Crawler
  def self.start(store)
    new.start(store)
  end

  def start(store)
    @session = Capybara::Session.new(:poltergeist)
    auth(store)
    visit_catalog()
    promotions = get_promotions()
    exclude_without_offers(promotions)
    offers = collect_offers(promotions)
    offers = sort(offers)
    if store == :tech
      LostOffers.lost_tech(offers).deliver!
    elsif store == :sport
      LostOffers.lost_sport(offers).deliver!
    end
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

        if match_data
          match_data[1].to_i <= 1
        else
          true
        end

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

  def auth(store)
    @session.visit('/')
    if store == :sport
      set_cookies_for_sport
    elsif store == :tech
      set_cookies_for_tech
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

  def set_cookies_for_tech
    if @session.mode == :selenium
      @session.driver.browser.manage.add_cookie(name: '__userid', value: '22261',
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')

      @session.driver.browser.manage.add_cookie(name: '__checksum', value: '645f839adcb5699a5df816c5554d99c3',
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')

    elsif @session.mode == :poltergeist
      @session.driver.set_cookie('__userid', '22261',
                                 expires: (Time.now + 1.month))

      @session.driver.set_cookie('__checksum', '645f839adcb5699a5df816c5554d99c3',
                                 expires: (Time.now + 1.month))

    end

  end


  def set_cookies_for_sport
    if @session.mode == :selenium
      @session.driver.browser.manage.add_cookie(name: '__userid', value: '25549',
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')

      @session.driver.browser.manage.add_cookie(name: '__checksum', value: 'f14ea2a33222f939bc20082c13dbdf58',
                                                expire: (Date.today + 1.month).to_s,
                                                domain: '1k.by', path: '/')

    elsif @session.mode == :poltergeist
      @session.driver.set_cookie('__userid', '25549',
                                 expires: (Time.now + 1.month))

      @session.driver.set_cookie('__checksum', 'f14ea2a33222f939bc20082c13dbdf58',
                                 expires: (Time.now + 1.month))


    end

  end

end
