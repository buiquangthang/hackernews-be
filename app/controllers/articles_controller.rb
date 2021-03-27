class ArticlesController < ApplicationController
  def index
    scraper = Scraper.new
    scraper.run

    json_response(scraper.results)
  end

  def show
  end
end
