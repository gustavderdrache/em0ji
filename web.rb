
require 'sinatra'
require 'net/http'
require 'json'


class Emojiton < Struct.new(:short, :url, :type)
  include Comparable

  def <=>(anOther)
    short <=> anOther.short
  end
end

def nomoji
  $emoji = nil
end

def emoji
  $emoji ||= fetch_all
end

def fetch_all
  emoji = []

  fetch_type('global').each do |short, url|
    emoji << Emojiton.new(short, url, 'global')
  end

  fetch_type('group').each do |short, url|
    emoji << Emojiton.new(short, url, 'group')
  end

  emoji
end

def fetch_type(type='all')
  puts 'fetch'
  next_url = 'https://api.hipchat.com/v2/emoticon?'
  auth_token = '&type='+ type + '&auth_token=' + ENV['HIPCHAT_TOKEN']

  emoji = {}
  while next_url
    val = fetch_page(next_url, auth_token)
    if val[:more] and val[:items].length > 0
      next_url = val[:more]
    else
      next_url = nil
    end
    emoji.merge!(val[:items])
  end
  emoji
end

def fetch_page(url, token)
  res = JSON.parse(Net::HTTP.get(URI(url + token)))
  out = res['items'].inject({}) do |r,v|
    r[v['shortcut']] = v['url']
    r
  end
  result = {items: out}
  result[:more] = res['links']['next'] if res['links']['next']
  result
end

get '/' do
  erb :index, :locals => { emoji: emoji.sort }
end

delete '/' do
  nomoji
end

