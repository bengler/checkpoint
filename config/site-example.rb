if not defined?SITE_LOADED
  SITE_LOADED = true

  require "etc"
  require "logger"
  require "yaml"

  # Determine environment
  ENV['RACK_ENV'] ||= "development"
  $environment = ENV['RACK_ENV']

  # Ensure that we're running as app user
  if ['production', 'staging', 'preprod'].include?($environment) and Etc.getpwuid(Process.uid).name != $app_name
    abort "Command must be run as user '#{$app_name}' (sudo -u #{$app_name})."
  end

  # Load application configuration for environment
  $app_config = YAML::load(File.open("config/config.yml"))[$environment]

  # Load Bundler gems
  require "bundler"
  Bundler.require

  # Setup logger for common.log
  if $app_config['log_path']
    FILELOGGER = Logger.new(File.join($app_config['log_path'], 'common.log'))
    FILELOGGER.level = Logger::INFO
  end

  # Setup logger for Logstash
  if defined?(LogStashLogger) && $app_config['logstash']
    LOGSTASH = LogStashLogger.new($app_config['logstash'])
    LOGSTASH.level = Logger::INFO
  end

  # Log to both common.log and Logstash
  if defined?(ContextualLogger::MultiLogger)
    LOGGER = ContextualLogger::MultiLogger.new(
      defined?(FILELOGGER) && FILELOGGER, defined?(LOGSTASH) && LOGSTASH)
  elsif defined?(FILELOGGER)
    LOGGER = FILELOGGER
  end

  if defined?(LOGGER)
    # Log exception causing application to exit
    at_exit do
      if $! and not $!.is_a? SystemExit and not $!.is_a? SignalException
        if $!.respond_to?(:backtrace)
          LOGGER.fatal [$!, $!.backtrace].flatten.join("\n")
        else
          LOGGER.fatal $!
        end
      end
    end

    # Attach logger to some common systems
    ActionMailer::Base.logger = LOGGER if defined?(ActionMailer::Base)
    ActiveRecord::Base.logger = LOGGER if defined?(ActiveRecord::Base)
    Dalli.logger = LOGGER if defined?(Dalli)
    Delayed::Worker.logger = LOGGER if defined?(Delayed)
  end

  # Set up Dalli to namespace with app name and revision as default
  if defined?(Dalli)
    class Dalli::Client
      # Set some default options for Dalli
      alias_method :initialize_wo_defaults, :initialize
      def initialize(servers=nil, options = {})
        defaults = {
          :namespace  => "#{$app_name}:" + `git rev-parse HEAD`[0..6],
          :compress   => true,
          :expires_in => 24 * 60 * 60
        }
        initialize_wo_defaults(servers, defaults.merge(options))
      end
    end
  end
end
