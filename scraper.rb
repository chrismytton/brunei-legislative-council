require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/core_ext'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  people = noko.xpath('//div[@class="ms-rte-layoutszone-inner"]//table//td//a[contains(@href, ".aspx")]/@href')
  people.each do |person_path|
    # Workaround for UTF-8 characters in the url which upset URI.join
    person_path = URI.escape(URI.unescape(person_path.to_s))
    person_url = URI.join(url, person_path)
    scrape_person(person_url)
  end
end

def scrape_person(url)
  noko = noko_for(url)
  name = noko.css('#DeltaPlaceHolderPageTitleInTitleArea').first.text.tidy
  warn "Scraping #{name}"
  data = {
    name: name,
    picture: URI.join(url, noko.css('.ms-rte-layoutszone-inner img').first[:src]).to_s,
    term: 11,
    source: url.to_s
  }
  ScraperWiki.save_sqlite([:name, :term], data)
end

term = {
  id: 11,
  name: 'Term 11',
  start_date: '2015-03-05',
  end_date: '2015-03-24'
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://majlis-mesyuarat.gov.bn/JMM%20Site%20Pages/Profil%20Ahli-Ahli%20Majlis%20Mesyuarat%20Negara.aspx')
