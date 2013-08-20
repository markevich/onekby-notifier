require 'capybara/rails'
Capybara.run_server = false
Capybara.app_host = 'http://1k.by'

class Crawler
  def self.start
    new.start
  end

  def start
    @session = Capybara::Session.new(:selenium)
    auth()
    visit_catalog()
    rows = get_promotions()
    exclude_without_offers(rows)
    offers = collect_offers(rows)
    offers
  end

  private

  def collect_offers(categories)
    categories.each do |category|
      @session.visit(category[:inner_link])
      offers = deep_collect_offers()
      table = @session.evaluate_script("$('table.fs-lrg').html()")
      doc = Nokogiri::HTML(table)
      rows = doc.xpath('//tbody/tr')
      details = rows.collect do |row|
        detail = {}
        [
          [:title, 'td[1]'],
          [:position, 'td[2]'],
          [:bet, 'td[3]'],
        ].each do |name, xpath|
          detail[name] = row.at_xpath(xpath).text.strip
        end
        detail
      end

      debugger
      1
    end
  end

  def deep_collect_offers
    table = @session.evaluate_script("$('table.fs-lrg').html()")
    doc = Nokogiri::HTML(table)
    rows = doc.xpath('//tbody/tr')
    details = rows.collect do |row|
      detail = {}
      [
        [:title, 'td[1]'],
        [:position, 'td[2]'],
        [:bet, 'td[3]'],
      ].each do |name, xpath|
        detail[name] = row.at_xpath(xpath).text.strip
      end
      detail
    end
    return details unless @session.has_link?('Следующая')
    @session.click_link('Следующая')

    details << deep_collect_offers.flatten
    details
  end

  def exclude_without_offers(rows)
    rows.delete_if do |row|
      row[:offers_count].to_i == 0
    end
  end

  def visit_catalog
    @session.visit('/users/shops-productscategoriespromotion')
  end

  def auth()
    @session.visit('/')
    set_cookies()
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

  def set_cookies
    @session.driver.browser.manage.add_cookie(name: '__userid', value: '22261',
                                              expire: (Date.today + 1.month).to_s,
                                              domain: '1k.by', path: '/')

    @session.driver.browser.manage.add_cookie(name: '__checksum', value: 'aa3ee85b644cb0abc4ba979bf7818c67',
                                              expire: (Date.today + 1.month).to_s,
                                              domain: '1k.by', path: '/')

    @session.driver.browser.manage.add_cookie(name: 'bbsessionhash', value: '326b15a783acbe3c4df5c5d2c7db4ec2',
                                              expire: (Date.today + 1.month).to_s,
                                              domain: '1k.by', path: '/')
  end
end
