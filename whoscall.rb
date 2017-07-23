require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'nokogiri'
require 'pry-byebug'
include Capybara::DSL

phonenumber = ARGV[0]
phonenumber ||= ""

country = ARGV[1]
country ||= "Taiwan"

options = {
  :window_size => [1280, 800],
  :js_errors => false
}

Capybara.javascript_driver = :poltergeist
Capybara.current_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end

url = "https://number.whoscall.com"
visit(url)

if phonenumber == ""
  puts "value 1: Please input phone number"
  puts "value 2: Please input country (optional), Default: Taiwan"
  exit
end

find('div.selected-flag').trigger('click')

all('ul.country-list li').each do |option|
  if option.text.include?(country)
    option.trigger('click')
  end
end

find('input.input-phonenumber').set(phonenumber)
country = find('div.selected-flag[title]').text

save_screenshot()

find('button.btn-search').trigger('click')

if page.has_selector?('input.error')
  puts "Please enter a phone number containing area code"
  exit
end

time = 0
while !page.has_selector?('h1.number-info__name') do
  sleep(1)
  time += 1
  puts "Zzz... #{time} sec"
  break if time > 200
end

if time > 200
  puts "Sleep more than 200 seconds to stop the crawler"
  exit
end

search_Result = Nokogiri::HTML(page.body)
s_result_title = search_Result.css('h1.number-info__name').text.strip
s_result_type = search_Result.css('p.number-info__category').text.strip

puts "#{country} #{phonenumber} : #{s_result_title}"

if page.has_selector?('div.address')
  address = search_Result.css('div.address address span').text
  puts "Address: #{address}"
end

puts "Type: #{s_result_type}" 

if page.has_selector?('div.ohours')
  puts "-------------"
  ohours = search_Result.css('div.ohours')
  ohours_now = ohours.css('h2.sub-title').text
  puts "Now: #{ohours_now}"
  puts "-------------"

  ohours_more_list = ohours.css('ul.ohours__list>li')

  ohours_more_list.each_with_index do |more_list|
    weekday = more_list.css('span.weekday').text
    puts "#{weekday}"
    
    weekday_time = more_list.css('ul li')
    weekday_time.each_with_index do |time|
      weekday_time = time.text
      puts "#{weekday_time}"
    end
    puts "-------------"
  end
end

save_screenshot()