require 'plex-ruby'
require 'open-uri'

module Plex
  def self.open(url)
    headers = {}
    headers["X-Plex-Client-Identifier"] = ENV['PLEX_CLIENT_ID']
    headers['X-Plex-Token'] = ENV['PLEX_TOKEN']
    headers['X-Plex-Username'] = ENV['PLEX_USER']

    super(url, headers)
  end
end

headers = {}
headers["X-Plex-Client-Identifier"] = ENV['PLEX_CLIENT_ID']
headers['X-Plex-Token'] = ENV['PLEX_TOKEN']
headers['X-Plex-Username'] = ENV['PLEX_USER']

host = ENV['PLEX_HOST']
port = ENV['PLEX_PORT']

SCHEDULER.every '5m', :first_in => 5 do |job|
  server = Plex::Server.new(host, port)

  recent = Array.new
  server.library.sections.each do |section|
    section.recently_added.take(50).each do |video|
      v = Hash.new
      if section.type == 'show'
        v['title'] = video.grandparent_title
        v['thumb'] = video.grandparent_thumb
      elsif section.type == 'movie'
        v['title'] = video.title
        v['thumb'] = video.thumb
      end
      v['added_at'] = video.added_at
      v['viewed'] = video.respond_to? 'view_count'
      recent << v
    end
  end

  recent.select! do |r|
    not r['viewed']
  end

  uniques = Array.new
  uniq = recent.delete_if do |video|
    in_list = false
    if uniques.include? video['title']
      in_list = true
    else
      uniques << video['title']
    end
    in_list
  end

  uniq.sort! do |x,y|
    x['added_at'] <=> y['added_at']
  end

  display = uniq.reverse.take(5)

  # check if image exists in images folder
  # if not download it
  display.each do |disp|
    filename = disp['thumb'].split("/").last(3).join(".") + '.jpg'
    # don't like this mutation of a reference, but nbd
    disp['filename'] = filename
    # not sure what the working directory will be once this runs
    filepath = File.expand_path("../..", __FILE__) + '/assets/images/thumbs/' + filename
    if not File.exist? filepath
      uri = 'http://' + ENV['PLEX_HOST'] + ':' + ENV['PLEX_PORT'] + disp['thumb']
      open(uri, headers) do |thumb|
        File.open(filepath, 'wb') do |file|
          file.puts thumb.read
        end
      end
    end
  end

  # refresh?
  # send_event('refresh_sample', {event: 'reload', dashboard: 'sample'}, 'dashboards')

  # send event with display hashes (arrays? strings?)
  send_event('plex', { 'vids': display })
end
