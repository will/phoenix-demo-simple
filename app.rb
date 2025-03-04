require 'sinatra'

set :port, Integer(ENV.fetch("PORT", "5678"))
get '/' do
  "Current system time: #{Time.now.utc}"
end
