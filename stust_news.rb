require_relative 'common'
require_relative 'common_stust'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'nokogiri'
require 'pry'
include Capybara::DSL

options = {
  :window_size => [1280, 800],
  :js_errors => false
}

Capybara.javascript_driver = :poltergeist
Capybara.current_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end

newsBaseURL = "http://news.stust.edu.tw/id/"
url = "http://news.stust.edu.tw/User/UserShowNewsList.aspx"
visit(url)

news_table_css = "table#ctl00_ContentPlaceHolder1_gv_NewsList "
news_table_tr_td_css = "tr:not(:first-child):not(:last-child) td:nth-child(2)"
news_table_date_css = "tr:not(:first-child):not(:last-child) td:last-child"
news_title_css = "h4.flow-text span"

_page = ARGV[0]
_page ||= 1
_page = _page.to_i

mode = ARGV[1]

if _page == 1
  puts "value 1: Please input the number of pages printed (optional)"
  puts "value 2: mode (optional)，'d' -> Debug mode (filter)，'s' -> Single news"
end

@filter_bool = true
@filter_save_bool = false
@filter_str = ""
@filter_save_str = ""

i, j = 0, 0

if mode == 's'
  news_url = "#{newsBaseURL}#{_page}"
  visit(news_url)
  _sleep(1, 16, news_title_css)
  newsHTML = Nokogiri::HTML(page.body)
  news_title = newsHTML.css(news_title_css).text
  news_date = newsHTML.css("span#ctl00_ContentPlaceHolder1_lbl_date").text
  news_deptname = newsHTML.css("span#ctl00_ContentPlaceHolder1_lbl_deptname").text
  news_content = newsHTML.css("span#ctl00_ContentPlaceHolder1_lbl_content").inner_html.gsub(/(<br>)+/, "\n")
  news_attachments = newsHTML.css("h6.flow-text a.black-text")
  puts news_url
  puts news_title
  puts news_date
  puts "發佈單位：" + news_deptname
  puts "------------------------------------------"
  puts news_content
  puts "------------------------------------------"
  news_attachments.each do |attachment|
    news_attachment_text = attachment.text
    news_attachment_url = attachment.values[1]
    puts "#{news_attachment_text}  #{news_attachment_url}"
  end
else
  while i < _page do
    news_list = all(news_table_css + news_table_tr_td_css)
    news_date_list = all(news_table_css + news_table_date_css)
    news_list_count = news_list.count
    puts "------------------------- 第 #{i + 1} 頁 -------------------------"
    
    while j < news_list_count do
      _sleep(1, 16, news_table_css)

      news = news_list[j].find('div.list_menu a')
      news_title = news[:title]
      news_url = news[:href]
      news_date = news_date_list[j].text
      news_no = j + 1 + (i * news_list_count)
      news_no = "%03d" % news_no
      news_puts_text = "No.#{news_no}: #{news_date} #{news_url}"
      _filter(news_title)

      if @filter_save_bool
        if mode == 'd'   # debug mode
          puts "#{news_puts_text} '#{@filter_save_str}': #{news_title}"
        else
          puts "#{news_puts_text} : #{news_title}"
        end
      elsif !@filter_bool and mode == 'd'   # debug mode
        puts "Filter: #{news_date} #{news_url} '#{@filter_str}': #{news_title}"
      elsif @filter_bool
        news_list[j].find('div.list_menu a').trigger('click')
        _sleep(1, 16, news_title_css)
        newsHTML = Nokogiri::HTML(page.body)
        news_title = newsHTML.css(news_title_css).text

        if @filter_bool
          if mode == 'd'   # debug mode
            puts "#{news_puts_text} '#{@filter_save_str}': #{news_title}"
          else
            puts "#{news_puts_text} : #{news_title}"
          end
        elsif !@filter_bool and mode == 'd'   # debug mode
          puts "Filter: #{news_date} #{news_url} '#{@filter_str}': #{news_title}"
        end

        page.go_back
        news_list = all(news_table_css + news_table_tr_td_css)
        news_date_list = all(news_table_css + news_table_date_css)
      end
      j += 1
    end
    j = 0
    i += 1
    visit("http://news.stust.edu.tw/User/UserShowNewsList.aspx?page=#{i}")
  end
end