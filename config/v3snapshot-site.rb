if not defined?SITE_LOADED
  SITE_LOADED = true

  require "etc"
  require "logger"
  require "syslog"

  # Set up environment
  ENV["RACK_ENV"] ||= ENV["RAILS_ENV"] || "development"
  ENV["RAILS_ENV"] = ENV["RACK_ENV"]

  # Ensure that we're running as app user
  if ['production', 'staging', 'preprod'].include?ENV["RACK_ENV"] and Etc.getpwuid(Process.uid).name != "checkpoint"
    abort "Command must be run as user 'checkpoint' (sudo -u checkpoint)."
  end

  # Set up logging to syslog
  raise "LOGGER already defined." if defined?(LOGGER)

  LOGGER = Class.new(Logger) do # anonymous class instance, think lambda
    attr_accessor :prefix

    # add severity, timestamp and (optional) thread name
    def format_message(severity, timestamp, progname, msg)
      sprintf "%s,%03d %7s: %s%s\n",
      timestamp.strftime("%Y-%m-%d %H:%M:%S"),
      (timestamp.usec / 1000).to_s,
      severity,
      prefix.nil? ? "" : "#{prefix} ",
      msg
    end

    def initialize(logdev='log/common.log')
      @level = Logger::INFO
    end

    # Convenience method for exceptions, logs them and notifies Airbrake
    def exception(exception, rackenv=nil)
      fatal(exception.inspect)
      fatal(exception.backtrace.join("\n"))
    end

    # Ignore setting level, so gems can't override policy
    def level=(level)
    end
  end.new

  at_exit do
    if $! and not $!.is_a? SystemExit and not $!.is_a? SignalException
      LOGGER.exception($!)
    end
  end

  # Load Bundler gems
  require "bundler"
  b = Bundler.setup
  if b.gems['rails'].empty? # Load non-Rails projects
    Bundler.require
  elsif b.gems['rails'][0].version.to_s =~ /^2/ # Load Rails 2, barfs on Bundler.require
    require './config/boot'
  else # Load Rails 3 projects
    require 'rails/all'
    Bundler.require
  end
  if defined?(ActiveRecord::Base) && !b.gems['pg'].empty?
    require 'active_record/connection_adapters/postgresql_adapter'
  end

  # Attach logger to some common systems
  ActionMailer::Base.logger = LOGGER if defined?(ActionMailer::Base)
  ActiveRecord::Base.logger = LOGGER if defined?(ActiveRecord::Base)
  Dalli.logger = LOGGER if defined?(Dalli)
  Delayed::Worker.logger = LOGGER if defined?(Delayed)
  Rails.logger = LOGGER if defined?(Rails) and not Rails.version =~ /^2/

  ActiveSupport::Deprecation.silenced = true if defined?(ActiveSupport::Deprecation)

  # Set up Sinatra
  if defined?(Sinatra::Base)
    Sinatra::Base.set :dump_errors, false
    Sinatra::Base.set :show_exceptions, false
    Sinatra::Base.set :logging, false
    Sinatra::Base.error Exception do
      if env['sinatra.error']
        LOGGER.exception(env['sinatra.error'], env)
      else
        LOGGER.warn('Sinatra error without exception')
      end
      '<h1>Internal Server Error</h1>'
    end 
  end

  # Set up ActiveRecord with PostgreSQL
  if defined?(ActiveRecord::Base) and defined?(PG)
    class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      [:execute, :query, :exec_cache, :exec_no_cache].each do |name|
        next unless method_defined?name
        define_method("#{name}_with_connection_failure_recovery") do |*args|
          begin
            send("#{name}_without_connection_failure_recovery", *args)
          rescue ActiveRecord::StatementInvalid, PG::Error => e
            if not @in_connection_recovery and @connection.status == PG::Connection::CONNECTION_BAD and open_transactions == 0
              if (logger = ActiveRecord::Base.logger) && logger.respond_to?(:warn)
                logger.warn("Database connection failure, reconnecting")
              end
              @in_connection_recovery = true
              reconnect!
              @in_connection_recovery = false
              send("#{name}_without_connection_failure_recovery", *args)
            else
              raise e
            end
          end
        end
        alias_method_chain name, :connection_failure_recovery
      end
    end
  end

  # Comma-separated list of memcache servers with port
  ENV['MEMCACHE_SERVERS'] = "zettmemcached.snapshot.api.no:11211"

  # Set up Dalli
  if defined?(Dalli)
    class Dalli::Client
      # Set some default options for Dalli
      alias_method :initialize_wo_defaults, :initialize
      def initialize(servers=nil, options = {})
        defaults = {
          :namespace => "checkpoint:" + `git rev-parse HEAD`[0..6],
          :compress => true,
          :expires_in => 60*60*24
        }
        initialize_wo_defaults(servers, defaults.merge(options))
      end
    end
  end
end
# Since site.rb.erb is regularly synced with the production environment, no 
# custom code should reside there. This file is appended to site.rb and should 
# contain all hacks^H^H^H^H^Hconfig specific to the development environment.

if not defined?(SITE_ADDENDUM_LOADED)
  SITE_ADDENDUM_LOADED = true

  # A beaoooootifol hack to add a Sinatra::Reloader to any and all sinatra-apps
  # created in this environment. It works by hooking the inherited-event on the
  # Sinatra::Base class as the reloader has to be registerd before any routes
  # are added.
  # This hack is triggered whenever the sinatra-contrib-gem is part of the bundle.
  if Bundler.setup.gems['sinatra-contrib'].any?
    require 'sinatra/reloader'
    LOGGER.info("Attaching Sinatra::Reloader Autoplay")
    Sinatra::Base.class_eval do
      class << self
        alias original_inherited inherited
        def inherited(klass)
          original_inherited(klass)        
          klass.class_eval do
            configure :development do            
              register Sinatra::Reloader
              also_reload "api/**/*.rb"
              also_reload "api/**/*.pg"
              also_reload "api/**/*.erb"
              also_reload "api/**/*.fu"
              also_reload "lib/**/*.rb"
            end
          end
        end
      end
    end
  end
  # Override Sinatra production settings for dev
  if defined?(Sinatra::Base)
    Sinatra::Base.set :dump_errors, true
    Sinatra::Base.set :show_exceptions, :after_handler
    Sinatra::Base.set :logging, true
  end
end
