SCHEDULER.every '5m', :first_in => 0 do
  send_event('refresh_sample', {event: 'reload', dashboard: 'sample'}, 'dashboards')
end
