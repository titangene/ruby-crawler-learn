require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'nokogiri'
require 'pry-byebug'
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

def _sleep(t, t_max, css)
  time = 0
  while !page.has_selector?(css) do
    sleep(t)
    time += t
    puts "#{css} - Zzz... #{time} sec"
    break if time > t_max
  end

  if time > t_max
    puts "Sleep more than #{t_max} seconds to stop the crawler"
    exit
  end
end

url = "http://news.stust.edu.tw/User/UserShowNewsList.aspx"
visit(url)

news_table_css = "table#ctl00_ContentPlaceHolder1_gv_NewsList "
news_table_tr_td_css = "tr:not(:first-child):not(:last-child) td:nth-child(2)"
news_title_css = "span#ctl00_ContentPlaceHolder1_FormView1_TitleLabel"
news_page_css = "tr:last-child td table td"

filters = ["約聘", "助理", "工讀生", "計畫徵求", "計畫申覆", "自主培育", "招標", "二技申請入學", 
  "暑假轉學考", "暑修", "毒家新聞", "四技甄選入學", "優活館", "四技甄選", "二、四技進修部",
  "繪圖設計", "職場體驗", "大學部新生", "登革熱", "暑期第", "進修部轉學生", "幼兒",
  "陸生暑假", "從業人員甄試", "國民小學", "中等學校", "臺南市政府社會局", "租屋", 
  "電影競賽", "日間部轉學生", "計畫性維護", "日間部轉學考", "暑假出入", "金融專業證照", 
  "徵文比賽", "專案教師", "四技甄選入學", " 徵 ", "禽肉", "汙水", "資源回收", "宿舍", 
  "國防工業展", "日大學部第", "國家圖書館", "餐旅", "藝廊", "攝影", "藝術學報", "實習", 
  "廣播", "產學計畫", "SolidWorks", "環境保護", "職棒", "進修部10", "服務業", 
  "教育學報", "微電影"]

filters_save = ["碩士", "研討會", "碩延", "程式競賽", "論文", "講座", "創業", "正職", 
  "職涯", "研究生", "雲端"]

_page = ARGV[0]
_page ||= 1
_page = _page.to_i

debug_mode = ARGV[1]

i, j = 0, 0

while i < _page do
  news_list = all(news_table_css + news_table_tr_td_css)
  news_list_count = news_list.count
  puts "------------------- 第 #{i + 1} 頁 -------------------"
  
  while j < news_list_count do
    _sleep(1, 16, news_table_css)
    news_list[j].find('div.list_menu a').trigger('click')
    _sleep(1, 16, news_title_css)
    newsHTML = Nokogiri::HTML(page.body)
    news_title = newsHTML.css(news_title_css).text

    filter_bool = true
    filter_str = ""
    filter_save_str = ""

    filters.each do |filter|
      if news_title.include?(filter)
        filter_str = filter
        filter_bool = false
        break
      end
    end

    filters_save.each do |filter|
      if news_title.include?(filter)
        filter_save_str = filter
        filter_bool = true
        break
      end
    end

    if debug_mode == 'd'
      if filter_bool
        news_no = j + 1 + (i * news_list_count)
        puts "No #{news_no}: '#{filter_save_str}': #{news_title}"
      else
        puts "過濾: '#{filter_str}': #{news_title}"
      end
    else
      if filter_bool
        news_no = j + 1 + (i * news_list_count)
        puts "No #{news_no}: #{news_title}"
      end
    end

    page.go_back
    news_list = all(news_table_css + news_table_tr_td_css)
    j += 1
  end
  j = 0
  i += 1
  visit("http://news.stust.edu.tw/User/UserShowNewsList.aspx?page=#{i}")
end

# news = all(news_table_css + news_table_tr_td_css)[0]
# _sleep(1, 16, news_table_css)
# news.find('div.list_menu a').trigger('click')
# _sleep(1, 16, news_title_css)
# newsHTML = Nokogiri::HTML(page.body)
# news_title = newsHTML.css(news_title_css).text
# puts news_title
# #visit(url)
# page.go_back

# news = all(news_table_css + news_table_tr_td_css)[1]
# _sleep(1, 16, news_table_css)
# news.find('div.list_menu a').trigger('click')
# _sleep(1, 16, news_title_css)
# newsHTML = Nokogiri::HTML(page.body)
# news_title = newsHTML.css(news_title_css).text
# puts news_title

