require 'nokogiri'
require 'open-uri'
require 'csv'
require 'time'

url = "https://oz.by/electronics/"

ITEMS_ON_PAGE_XPATH = "//li[@class='viewer-type-card__li ']/div/div/div/a/@href"
CURRENT_PAGE_XPATH = "//a[@class='g-pagination__list__item g-pagination__list__item_active']"
NEXT_PAGE_XPATH = "//link[@rel='next']/@href"
ITEM_NAME_XPATH = "//h1[@itemprop='name']"
ITEM_COST_XPATH = "//span[@class='b-product-control__text b-product-control__text_main']"

class Parser

  def initialize
    @numbers_of_items = 0
    @csv_strings = 0
    CSV.open("oz-by-electronics.csv", 'a') {|csv| csv << ["Name; Price; Page"]}
  end

  def doc(url)
    html = URI.open(url)
    doc = Nokogiri::HTML(html)
    @current_page = doc.xpath(CURRENT_PAGE_XPATH).text
    items_on_page = doc.xpath(ITEMS_ON_PAGE_XPATH).size
    puts "="*50, "Page: #{@current_page}; Items on page: #{items_on_page}.", url
    page(doc)
  end

  def page(doc)
    doc.xpath(ITEMS_ON_PAGE_XPATH).each do |url|
      puts "-"*50
      @numbers_of_items += 1
      puts "Item: #{@numbers_of_items}; Url: https://oz.by#{url}"
      item(url)
    end
    next_page(doc)
  end

  def item(url)
    html = URI.open("https://oz.by#{url}")
    doc = Nokogiri::HTML(html)
    item_name = doc.xpath(ITEM_NAME_XPATH).text.split(' ')[0].gsub('"',"'").gsub(",","-")
    item_price = doc.xpath(ITEM_COST_XPATH).text.split(' ')[0].sub(",",".")
    puts "Name: #{item_name}", "Price: #{item_price}"
    csv_writer(item_name, item_price, "oz.by" + url)
  end

  def csv_writer(item_name, item_price, url)
    @csv_strings += 1
    CSV.open("oz-by-electronics.csv", 'a') {|csv| csv << [item_name, item_price, url]}
  end

  def count
    puts "="*50
    puts "Successfully completed!"
    puts "Pages: #{@current_page}; Items: #{@numbers_of_items}; Strings: #{@csv_strings}"
  end

  def next_page(doc)
    next_page_url = doc.xpath(NEXT_PAGE_XPATH).text
    next_page_url != "" ? doc(next_page_url) : count
  end
end

start_time = Time.now
Parser.new.doc(url)
work_time = Time.now - start_time
puts "Time of parsing: #{Time.at(work_time).utc.strftime("%H:%M:%S")}"
