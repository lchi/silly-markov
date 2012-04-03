require 'rubygems'
require 'tweetstream'

# New Jersey..
swcorner = [39.066114,-75.333252]
necorner = [40.5472,-73.927002]

jersey  = swcorner << necorner
key = File.new('.twitter_cs_key').read.strip
secret = File.new('.twitter_cs_secret').read.strip
token = File.new('.twitter_token').read.strip
token_secret = File.new('.twitter_token_secret').read.strip

TweetStream.configure do |config|
  config.consumer_key = key
  config.consumer_secret = secret
  config.oauth_token = token
  config.oauth_token_secret = token_secret
  config.auth_method = :oauth
  config.parser   = :json_pure
end

client = TweetStream::Client.new

client.on_error do |message|
  puts message
end

client.sample do |status|
  p "#{status}"
  puts "#{status.text}"
end
