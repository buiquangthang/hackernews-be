require 'rails_helper'

RSpec.describe 'Articles API', type: :request do
  describe 'GET /articles' do
    it "returns articles" do
      VCR.use_cassette "scrape data", record: :new_episodes do
        get '/articles?p=2'

        response_data = json['data']

        expect(response_data).not_to be_empty
        expect(response_data.size).to eq(30)
      end
    end

    it "returns status code 200" do
      VCR.use_cassette "scrape data", record: :new_episodes do
        get '/articles?p=2'
        expect(response).to have_http_status(200)
      end
    end

    it "returns empty data when page number over maximum page" do
      VCR.use_cassette "scrape data", record: :new_episodes do
        get '/articles?p=100'

        response_data = json['data']

        expect(response_data).to be_empty
      end
    end
  end
end
