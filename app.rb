require 'sinatra'

get '/' do
  "Current system time: #{Time.now.utc}"
end
