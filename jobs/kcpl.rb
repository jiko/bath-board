require 'rubygems'
require 'mechanize'

SCHEDULER.every '1d', :first_in => 0 do |job|
  agent = Mechanize.new { |a|
      a.user_agent_alias = 'Mac Safari'
  }

  login = agent.get('https://ala.kcpl.com/ala/mainLogin.cfm')
  form = login.form('login')
  form.username = ENV['KCPL_USER']
  form.password = ENV['KCPL_PASS']

  landing = agent.submit(form)

  # daily_usage_uri = 'https://ala.kcpl.com/ala/scrDailyUse.cfm'
  daily_usage = landing.link_with(text: /Daily Usage/).click

  # csv_dwnld_uri = 'https://ala.kcpl.com/ala/_dailyUsage/DwnldDayUsgCht.cfm?meterID=1224715882569&avgCst=0.126'
  download_link = daily_usage.link_with(text: /Download/)
  csv = agent.get(download_link.href)
  csv.save!
end
