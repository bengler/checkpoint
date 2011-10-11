require 'logger'
require 'active_support/core_ext/date_time/conversions'

module Loggable

  attr_accessor :logger

  class CheckpointLogger < Logger
    @@logs ||= {}

    class << self
      def log_path
        "#{Sinatra::Application.root}/log"
      end

      def use(basename)
        unless File.exists?(log_path)
          FileUtils.mkdir_p(log_path)
        end

        @@logs[basename] ||= self.new(File.open("#{log_path}/#{basename}_#{ENV['RACK_ENV']}.log", 'a'))
        @@logs[basename]
      end
    end

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
    end
  end

end
