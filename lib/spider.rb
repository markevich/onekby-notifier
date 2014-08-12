class Spider
  INCREASE_STEP = 0.5

  include BotConcern

  def initialize
  end

  def self.start(bot_id: 2)
    new.start(bot_id)
  end

  def start(bot_id)
    @bot = Bot.find(bot_id)
    @session = Capybara::Session.new(:poltergeist)

    begin
      auth(@bot)
      visit_catalog

      categories = get_categories
      save_categories(categories)

      categories_processing
    ensure
      @session.driver.quit
    end
  end

  def categories_processing
    @bot.categories.where(enabled: true).each do |category|
      # next unless category.id == 7
      @session.visit(category.link)
      go_through_category(1, category)
    end
  end

  def magic(offers)
    offers.each do |offer|
      @session.find(:xpath, "//a[contains(@onclick, 'productbid-#{offer[:product_id]}')]").click

      if offer[:raw_data].inner_html.include?('<span class="grey">-</span>')
        @session.find(:css, '.ui-dialog')
        new_bet = 1
      else
        @session.find(:css, '.ui-dialog table.fs-lrg')
        table = @session.evaluate_script("$('.ui-dialog table.fs-lrg').html()")
        doc = Nokogiri::HTML(table)
        rows = doc.xpath('//tbody/tr')

        good_bets = rows.reduce([]) do |result, row|
          if row.attr('class') != 'tb-h' && row.at_xpath('td[3]').attr('class') != 'td3 red'
            result << row.at_xpath('td[3]').text.to_f
          end
          result
        end

        good_bet = good_bets.find do |bet|
          bet < offer[:category][:max_bet] - INCREASE_STEP
        end
        new_bet = good_bet ? good_bet + INCREASE_STEP : 1
      end

      Rails.logger.info("New bet #{new_bet} for #{offer[:product_id]}")

      @session.execute_script("$('#bidid').val('#{new_bet}')")
      @session.click_button('Сохранить')
      @session.find("span", text: 'Информация сохранена')
      @session.find(:css, '.ui-icon-closethick').click
      sleep 0.5
    end
  end

  def go_through_category(page_number, category)
    @session.has_css?('span.pages', text: page_number.to_s)
    table = @session.evaluate_script("$('table.fs-lrg').html()")
    doc = Nokogiri::HTML(table)
    rows = doc.xpath('//tbody/tr')
    offers = rows.map do |row|
      next if row.attr('class') == 'tb-h'

      #1.0/1.0 (2)
      raw_bet = row.at_xpath('td[2]').text.strip
      position_regex = /(\d+\.\d+)\/(\d+\.\d+)\s\((.+)\)/
      position_parsed_data = raw_bet.match(position_regex)

      if raw_bet == '-'
        position_parsed_data = []
        position_parsed_data[1] = 0
        position_parsed_data[3] = 0
      end
      next if position_parsed_data.nil? || position_parsed_data[3].nil?

      {
        category: category,
        title: row.at_xpath('td[1]').text.strip,

        raw_bet: raw_bet,
        position: position_parsed_data[3].to_i,
        first_bet: position_parsed_data[1].to_f,

        bet: row.at_xpath('td[3]').text.strip,
        link: row.at_xpath('td[4]').text.strip,
        product_id: row.at_xpath('td[2]/span').attr('id').split('-').last,
        raw_data: row
      }
    end.compact

    offers.delete_if do |offer|
      offer[:position] == 1
    end

    magic(offers)

    return offers unless @session.has_link?('Следующая')
    Rails.logger.info("Clicked #{page_number + 1} page")
    @session.click_link((page_number + 1).to_s)

    deep_offers = go_through_category(page_number + 1, category).flatten
    offers.concat(deep_offers)
  end

  def save_categories(categories)
    categories.each do |cat|
      category = Category.find_or_initialize_by(bot: @bot, name: cat[:title])
      category.link = cat[:inner_link]
      category.save!
    end
  end
end
