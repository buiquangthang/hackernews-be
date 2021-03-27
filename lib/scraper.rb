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
    parent: {
      element: 'tr',
      name: 'athing',
      type: :class
    }
  }

  attr_accessor :options, :results, :url, :detail_page

  def initialize
    @options = DEFAULT_OPTIONS
    @url = @options[:base_url]
    @results = []
  end

  # This method will trigger our paginated scraper. It will get the first page result,
  # And use the specified parent element, identifier and attribute type to set the per page/ last page values if necessary.
  # and the last page for our options. Then we will trigger our paginated get with this new information.
  #
  # @param element [String] the HTML element for the recurring parent element on the page
    # ex: 'div' or 'h1'
  # @param name [String] the class or id name we can target on the element.
    # ex: 'listingCard' if the class name for the element we want to target is 'listingCard'
  # @param type [Symbol] the HTML attribute type for the recurring parent element on the page
    # ex: :class or :id
  def run
    page = scrape_page(@options[:base_url])

    @options[:per_page] = page.css(parent_target).count
    @options[:last_page] = get_last_page(@options[:total], @options[:per_page])

    paginated_get
  end

  # Specify the attribute type format needed for nokogiri data parsing
  #
  # @param type [Symbol] the attribute type on the html element
  # valid options currently are :class or :id
  # @return [String] the format needed for nokogiri data parsing ('.' for class or '#' for id)
  def set_attribute_type(type)
    type == :class ? '.' : '#'
  end

  # Set the parent element for nokogiri parsing
  # ex: 'div.listingCard'
  def parent_target
    parent = @options[:parent]

    return parent[:element] if parent[:name].nil? || parent[:type].nil?

    attribute_type = set_attribute_type(parent[:type])

    [parent[:element], attribute_type, parent[:name]].join
  end

  def scrape_page(url)
    begin
      puts url
      Nokogiri::HTML(HTTParty.get(url, verify_peer: false))
    rescue Exception => e
      nil
    end
  end

  # @param total [Integer] the total number of elements in the full data set
  # @param per_page [Integer] the number of elements per page
  def get_last_page(total, per_page)
    (total.to_f/per_page.to_f).ceil
  end

  def paginated_get
    return unless @options[:last_page]

    while @options[:current_page] <= @options[:last_page]
      get_next_page
      @options[:current_page] += 1
    end
  end

  def get_next_page
    page_url = [@url, @options[:path], '?', @options[:param], '=', @options[:current_page]].join

    data = scrape_page(page_url).css(parent_target)

    format_results(data)
  end

  def format_results(page_items)
    page_items.each { |page_item| @results << format_result(page_item) }
  end

  def format_result(page_item)
    crawl_data = {
      description: nil,
      image_url: nil
    }

    crawl_data[:title] = page_item.css('a.storylink').text
    crawl_data[:url] = page_item.css('a.storylink').first.attributes['href'].value

    detail_page = scrape_page(crawl_data[:url])

    unless detail_page.nil?
      meta_description = detail_page.css("meta[property='og:description']")
      if meta_description.any?
        crawl_data[:description] =  meta_description.first.attributes["content"].value.truncate(1024)
      end

      meta_image = detail_page.css("meta[property='og:image']")
      if meta_image.any?
        crawl_data[:image_url] = meta_image.first.attributes["content"].value
      end
    end

    crawl_data
  end
end
