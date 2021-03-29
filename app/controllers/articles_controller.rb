class ArticlesController < ApplicationController
  def index
    scraper = Scraper.new(scrape_options(params[:p]))
    scraper.run

    json_response(scraper.results)
  end

  def show
  end

  private

  def scrape_options(current_page = nil)
    {
      base_url: 'https://news.ycombinator.com',
      path: '/best',
      param: 'p',
      page: 1,
      per_page: 30,
      current_page: current_page.nil? ? 1 : current_page.to_i,
      get_next_page: false,
      parent: {
        element: 'tr',
        name: 'athing',
        type: :class
      }
    }
  end
end
