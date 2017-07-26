require_relative 'common'

require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'nokogiri'
require 'pry-byebug'
include Capybara::DSL

options = {
  #:window_size => [1280, 800],
  :js_errors => false
}

Capybara.javascript_driver = :poltergeist
Capybara.current_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end

url = "http://www.books.com.tw"
visit(url)

search_keyword = ARGV[0]
search_keyword ||= ""

if search_keyword == ""
  puts "value 1: Please input search keyword"
  exit
end

#find('a.close').trigger('click')
find('input.search_key').set(search_keyword)
find("button[title='搜尋']").trigger('click')

# 熱門關鍵字
# popular_keywords_str = "熱門關鍵字："
# all('div.type02_m001 ul li').each do |keyword|
#   popular_keywords_str << keyword.find('a').text + ", "
# end
# puts popular_keywords_str

_sleep(1, 20, 'ul.searchbook')

search_Result = Nokogiri::HTML(page.body)
book_lists = search_Result.css('ul.searchbook li.item')
book_lists_count = book_lists.count

#book_nextPage = find('div.page a.nxt').trigger('click')
#_sleep_has_content(1, 20, 'div.cntlisearch10 div.page span', '2')
#puts find('div.page a.nxt').text

search_Result = Nokogiri::HTML(page.body)
book_lists = search_Result.css('ul.searchbook li.item')
book_lists_count = book_lists.count

book_links = book_lists.css('h3 a').map { |link| link['href'] }
book_pages = search_Result.css('div.cntlisearch10 div.page span')
book_pages_count = book_pages[0].text
book_page_current = book_pages[1].text

puts "====== 第 #{book_page_current} 頁 | 共 #{book_pages_count} 頁 ======"

i = 5
#while i < 2 do
while i < book_lists_count do
  book_title = book_lists[i].css('h3').text.strip

  book_authors = book_lists[i].css('a[rel="go_author"]')
  book_authors_str = ""
  book_authors.each do |author|
    book_authors_str << author.text.strip + "，"
  end

  book_publish = book_lists[i].css('a[rel="mid_publish"]').text
  book_description = book_lists[i].css('p').text.strip.split("   ")
  book_description_str = ""
  book_description.each do |book_desc|
    book_description_str << book_desc
  end

  puts "----------------- No. #{i + 1} -----------------"
  puts "書名：#{book_title}"

  # 商品介紹
  visit(book_links[i])
  _sleep(1, 20, 'div.type02_p01_wrap')

  book_intro = Nokogiri::HTML(page.body)
  book_intro_data = book_intro.css('div.main_column div.type02_p003 ul li')
  book_intro_data_count = book_intro_data.count

  j = 0
  book_authors_str = ""
  has_translator = false
  book_translator = ""
  book_publication_date = ""
  book_lang = ""

  book_intro_data.each_with_index do |book_intro, index|
    if index == 0
      _book_authors = book_intro.css('a:not(:first-child):not(:nth-child(1)):not(:last-child):not(:nth-last-child(2))')
      _book_authors.each do |author|
        book_authors_str << author.text + "，"
      end
    elsif index == 1
      if book_intro.text.include?("譯者")
        has_translator = true
        book_translator = book_intro.text
      else
        book_publish = book_intro.css('a:first-child span').text 
      end
    elsif index == 2
      if book_intro.text.include?("出版社")
        book_publish = book_intro.css('a:first-child span').text 
      else
        book_publication_date = book_intro.text
      end
    elsif index == 3
      if book_intro.text.include?("出版日期")
        book_publication_date = book_intro.text
      else
        book_lang = book_intro.text
      end
    elsif index == 4
      book_lang = book_intro.text
    end
    j += 1
  end

  puts "作者：#{book_authors_str[0..-2]}"
  if has_translator
    puts book_translator
  end
  puts "出版社：#{book_publish}"
  puts book_publication_date
  puts book_lang
  puts "簡介：#{book_description_str}"

  book_price_data = book_intro.css('div.prod_cont_a ul.price li')
  book_price_data.each do |price|
    puts price.text
  end

  book_inStock = book_intro.css('div.box_2 ul.list li.no').text
  if book_inStock.text.include?("庫存")
    book_inStock_num = book_inStock.split("=")[1]
    puts "庫存：#{book_inStock_num}"
  else
    puts book_inStock
  end

  sleep(1)

  page.go_back
  i += 1
end