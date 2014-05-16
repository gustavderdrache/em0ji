
require 'sinatra'
require 'net/http'
require 'json'

$stdout.sync = true

def nomoji
  $emoji = nil
end

def emoji
  $emoji ||= fetch_all
end

def fetch_all
  puts 'fetch'
  next_url = 'https://api.hipchat.com/v2/emoticon?'
  auth_token = '&auth_token=' + ENV['HIPCHAT_TOKEN']

  emoji = {}
  while next_url
    val = fetch_page(next_url, auth_token)
    if val[:more]
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
  ret = "<style>body { margin-left: 100px; margin-right: 100px; } div { display: inline-block; height: 50px; min-width: 50px; padding: 8px; margin-top: 10px; } p { text-align: center; font-size: 10px; }</style>"
  emoji.each do |short,url|
    ret += '<div><p><img src="%s" /><br />(%s)</p></div>' % [url, short]
  end
  ret
end

delete '/' do
  nomoji
end

