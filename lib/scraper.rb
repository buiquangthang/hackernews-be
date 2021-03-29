class Scraper
  DEFAULT_OPTIONS = {
    base_url: 'https://news.ycombinator.com',
    path: '/best',
    param: 'p',
    page: 1,
    per_page: 30,
    total: 30,
    last_page: 4,
    current_page: 1,
    get_next_page: false,
    parent: {
      element: 'tr',
      name: 'athing',
      type: :class
    }
  }

  attr_accessor :options, :results, :url, :detail_page

  def initialize options = nil
    @options = options || DEFAULT_OPTIONS
    @url = @options[:base_url]
    @results = []
  end

  # This method will trigger our paginated scraper. It will get the first page result,
  # And use the specified parent element, identifier and attribute type to set the per page/ last page values if necessary.
  # and the last page for our options. Then we will trigger our paginated get with this new information.
  def run
    if @options[:get_next_page]
      page = scrape_page(@options[:base_url])

      @options[:per_page] = page.css(parent_target).count
      paginated_get
    else
      get_next_page
    end
  end

  private

  # Specify the attribute type format needed for nokogiri data parsing
  #
  # @param type [Symbol] the attribute type on the html element
  # valid options currently are :class or :id
  # @return [String] the format needed for nokogiri data parsing ('.' for class or '#' for id)
  def set_attribute_type(type)
    type == :class ? '.' : '#'
  end

  # Set the parent element for nokogiri parsing
  def parent_target
    parent = @options[:parent]

    return parent[:element] if parent[:name].nil? || parent[:type].nil?

    attribute_type = set_attribute_type(parent[:type])

    [parent[:element], attribute_type, parent[:name]].join
  end

  def scrape_page(url)
    begin
      Nokogiri::HTML(HTTParty.get(url, verify_peer: false))
    rescue Exception => e
      nil
    end
  end

  def paginated_get
    while @options[:per_page] > 0
      get_next_page
      @options[:current_page] += 1
    end
  end

  def get_next_page
    page_url = [@url, @options[:path], '?', @options[:param], '=', @options[:current_page]].join

    page_data = scrape_page(page_url)
    url_data = page_data.css(parent_target)
    subtext_data = page_data.css('td.subtext')

    @options[:per_page] = url_data.count

    format_results(url_data, subtext_data)
  end

  def format_results(page_items, subtext_items)
    page_items.each_with_index do |page_item, index|
      subtext_item = subtext_items[index]
      @results << format_result(page_item, subtext_item)
    end
  end

  def format_result(page_item, subtext_item)
    crawl_data = {
      description: nil,
      image_url: nil
    }

    story_link = page_item.css('a.storylink').first.attributes['href'].value

    Rails.cache.fetch(Digest::MD5.hexdigest(story_link), expires_in: 1.hour) do
      crawl_data[:url] = story_link
      crawl_data[:title] = page_item.css('a.storylink').text
      crawl_data[:author] = subtext_item.css('.hnuser').first.text
      crawl_data[:score] = subtext_item.css('.score').first.text
      crawl_data[:created_at] = subtext_item.css('span.age a').first.text

      detail_page = scrape_page(crawl_data[:url])

      unless detail_page.nil?
        meta_description = detail_page.css("meta[property='og:description']")
        if meta_description.any?
          crawl_data[:description] =  meta_description.first.attributes["content"]&.value&.truncate(1024)
        end

        meta_image = detail_page.css("meta[property='og:image']")
        if meta_image.any?
          crawl_data[:image_url] = meta_image.first.attributes["content"].value
        end
      end

      crawl_data
    end
  end
end
