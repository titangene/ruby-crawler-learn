require 'capybara'

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