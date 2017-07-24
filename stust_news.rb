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
news_table_date_css = "tr:not(:first-child):not(:last-child) td:last-child"
news_title_css = "span#ctl00_ContentPlaceHolder1_FormView1_TitleLabel"
news_page_css = "tr:last-child td table td"

@filters = ["約聘", "助理", "工讀生", "計畫徵求", "計畫申覆", "自主培育", "招標", "二技申請入學", 
  "暑假轉學考", "暑修", "毒家新聞", "四技甄選入學", "優活館", "四技甄選", "二、四技進修部", "繪圖設計", 
  "職場體驗", "大學部新生", "登革熱", "暑期第", "進修部轉學生", "幼兒", "陸生暑假", "動物之家", "藝術", 
  "從業人員甄試", "國民小學", "中等學校", "臺南市政府社會局", "租屋", "電影競賽", "日間部轉學生", 
  "計畫性維護", "日間部轉學考", "暑假出入", "金融專業證照", "徵文比賽", "專案教師", "四技甄選入學", 
  "禽肉", "汙水", "資源回收", "宿舍", "國防工業展", "日大學部第", "國家圖書館", "餐旅", "藝廊", "攝影", 
  "法務部", "實習", "廣播", "產學計畫", "SolidWorks", "環境保護", "職棒", "進修部10", "服務業", 
  "微電影", "搬運工", "英文教師", "英文老師", "國小", "治安季刊", "健康促進", "毒品", "文藝", "車床", 
  "志工", "進修部畢業", "自來水", "真善忍", "食安", "世大運", "徵稿", "水塔", "香港新生", "農業", 
  "打工", "水管", "四技進修部", "新南向", "這是您的機車", "服務學習", "海外聯招", "牧愛學堂", "海域", 
  "四技技優甄審", "宣傳海報", "視障者", "Photoshop CS6", "設備集中採購案", "暑期日間部", "國稅局", 
  "失智", "出國留學", "狂犬", "海龜", "文學獎", "勞作教育", "詩文", "進修部暑期", "轉部暨轉系", "流感", 
  "師資培育", "會計員", "通識教育", "釣魚台", "社會發展", "財政稅務局", "保險理賠", "升級作業", "反詐騙", 
  "學會會長", "暑假期間六宿", "樹林機車", "汽車通行", "四技技優", "自殺", "紫絲帶獎", "日間部(延修生)", 
  "身障", "看見台灣", "民眾資訊素養", "弱勢家庭", "反毒", "救國團", "四技甄試", "整修工程", "軍事訓練", 
  "機車事故", "治安簡訊", "詐騙", "暑期進修部", "時代潮流"]

@filters_save = ["碩士", "研討會", "碩延", "程式競賽", "論文", "創業", "講座", "正職", 
  "職涯", "研究生", "雲端", "資訊人員", "黑客松"]

_page = ARGV[0]
_page ||= 1
_page = _page.to_i

debug_mode = ARGV[1]

if _page == 1
  puts "value 1: Please input the number of pages printed (optional)"
  puts "value 2: input 'd' (optional) --> Debug mode (filter)"
end

@filter_bool = true
@filter_save_bool = false
@filter_str = ""
@filter_save_str = ""

def _filter(news_title)
  @filter_bool = true
  @filter_save_bool = false
  @filter_str = ""
  @filter_save_str = ""

  @filters.each do |filter|
    if news_title.include?(filter)
      @filter_str = filter
      @filter_bool = false
      break
    end
  end

  @filters_save.each do |filter|
    if news_title.include?(filter)
      @filter_save_str = filter
      @filter_bool = true
      @filter_save_bool = true
      break
    end
  end
end

i, j = 0, 0

while i < _page do
  news_list = all(news_table_css + news_table_tr_td_css)
  news_date_list = all(news_table_css + news_table_date_css)
  news_list_count = news_list.count
  puts "------------------------- 第 #{i + 1} 頁 -------------------------"
  
  while j < news_list_count do
    _sleep(1, 16, news_table_css)

    news_title =  news_list[j].find('div.list_menu a')[:title]
    news_date = news_date_list[j].text
    _filter(news_title)

    if @filter_save_bool
      news_no = j + 1 + (i * news_list_count)
      news_no = "%03d" % news_no
      if debug_mode == 'd'
        puts "No.#{news_no}: #{news_date} '#{@filter_save_str}': #{news_title}"
      else
        puts "No.#{news_no}: #{news_date} #{news_title}"
      end
    elsif !@filter_bool and debug_mode == 'd'
      puts "Filter: #{news_date} '#{@filter_str}': #{news_title}"
    elsif @filter_bool
      news_list[j].find('div.list_menu a').trigger('click')
      _sleep(1, 16, news_title_css)
      newsHTML = Nokogiri::HTML(page.body)
      news_title = newsHTML.css(news_title_css).text

      if @filter_bool
        news_no = j + 1 + (i * news_list_count)
        news_no = "%03d" % news_no
        if debug_mode == 'd'
          puts "No.#{news_no}: #{news_date} '#{@filter_save_str}': #{news_title}"
        else
          puts "No.#{news_no}: #{news_date} #{news_title}"
        end
      elsif !@filter_bool and debug_mode == 'd'
        puts "Filter: #{news_date} '#{@filter_str}': #{news_title}"
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