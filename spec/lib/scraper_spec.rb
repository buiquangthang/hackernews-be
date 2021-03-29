require 'rails_helper'

RSpec.describe Scraper do
  describe '#run' do
    let(:options) do
      {
        base_url: 'https://news.ycombinator.com',
        path: '/best',
        param: 'p',
        page: 1,
        per_page: 30,
        total: 30,
        current_page: 2,
        get_next_page: false,
        parent: {
          element: 'tr',
          name: 'athing',
          type: :class
        }
      }
    end

    it "returns results when get data in one page" do
      VCR.use_cassette "scrape one page", record: :once do
        scraper = Scraper.new(options)
        scraper.run

        expect(scraper.results.size).to eq(30)
      end
    end

    it "returns results when get data in multiple page" do
      VCR.use_cassette "scrape multiple page", record: :once do
        options[:get_next_page] = true
        options[:current_page] = 6

        scraper = Scraper.new(options)
        scraper.run

        expect(scraper.results.size).to be > 30
      end
    end
  end
end
