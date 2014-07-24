class Spider

  include BotConcern

  def initialize

  end

  def start(bot_id: 2)
    @bot = Bot.find(bot_id)
    @session = Capybara::Session.new(:selenium_firebug)
    auth(@bot)
    visit_catalog

    categories = get_categories
    save_categories(categories)

    categories_processing
  end

  def categories_processing
    @bot.categories(true).each do |category|
      @session.visit(category.link)
      go_through_category(1)
    end
  end

  def magic(offers)
    binding.pry
    offers.each do |offer|
      next unless  offers.first == offer

      @session.find(:xpath, "//a[contains(@onclick, '#{offers.first[:product_id]}')]").click
      @session.find('#bidid.text').set('0.5')
      # @session.evaluate_script("$('#bidid').val(0.5)")
      @session.click_button('Сохранить')
    end
  end

  def go_through_category(page_number)
    @session.has_css?('span.pages', text: page_number.to_s)
    table = @session.evaluate_script("$('table.fs-lrg').html()")
    doc = Nokogiri::HTML(table)
    rows = doc.xpath('//tbody/tr')
    offers = rows.map do |row|
      next if row.attr('class') == 'tb-h'

      {
        title: row.at_xpath('td[1]').text.strip,
        position: row.at_xpath('td[2]').text.strip,
        bet: row.at_xpath('td[3]').text.strip,
        link: row.at_xpath('td[4]').text.strip,
        product_id: row.at_xpath('td[2]/span').attr('id').split('-').last,
        raw_data: row
      }
    end.compact

    back = offers.first

    offers.delete_if do |offer|
      #1.0/1.0 (2)
      regexp = /\d+\.\d+\/\d+\.\d+\s\((.+)\)/
      match_data = offer[:position].match(regexp)

      if match_data
        match_data[1].to_i <= 1
      else
        true
      end
    end

    offers << back

    magic(offers)

    return offers unless @session.has_link?('Следующая')
    Rails.logger.info("Clicked #{page_number + 1} page")
    @session.click_link((page_number + 1).to_s)

    deep_offers = go_through_category(page_number + 1).flatten
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
