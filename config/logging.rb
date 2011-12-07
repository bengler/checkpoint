require 'logger'

Dir.mkdir('log') unless File.exist?('log')

logfile = File.new("log/#{Sinatra::Application.environment}.log", 'a+')

Log = Logger.new(logfile)
Log.level = Sinatra::Application.environment == :production ? Logger::WARN : Logger::DEBUG
Log.datetime_format = "%Y-%m-%d %H:%M:%S.%L"

unless Sinatra::Application.environment == :test
  STDERR.reopen(logfile)
end

CheckpointV1.use Rack::CommonLogger, logfile
