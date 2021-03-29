namespace :crawler do
  desc "TODO"
  task seed: :environment do
  	options = {
      base_url: 'https://news.ycombinator.com',
      path: '/best',
      param: 'p',
      page: 1,
      per_page: 30,
      current_page: 1,
      get_next_page: true,
      parent: {
        element: 'tr',
        name: 'athing',
        type: :class
      }
    }

    scraper = Scraper.new(options)
    scraper.run
  end

end
