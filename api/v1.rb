# encoding: utf-8
require "json"
require 'pebblebed/sinatra'
require 'sinatra/petroglyph'

Dir.glob("#{File.dirname(__FILE__)}/v1/**/*.rb").each{ |file| require file }

class CheckpointV1 < Sinatra::Base
  set :root, "#{File.dirname(__FILE__)}/v1"
  set :show_exceptions, false

  register Sinatra::Pebblebed

  error ActiveRecord::RecordNotFound do
    halt 404, "Record not found"
  end

  error Exception do |e|
    $logger.error e.message
    e.backtrace.each do |line|
      $logger.info line
    end
    halt 500, e.message
  end

  after do
    current_identity.mark_as_seen if current_identity
  end

  helpers do 
    def current_session_key
      params[:session] || request.cookies[Session::COOKIE_NAME]
    end

    def current_session
      return @current_session ||= session_from_cookie || new_session
    end

    def session_from_cookie
      if (key = current_session_key)
        session = Session.where("key = ?", key).first(:include => :identity)
        unless session
          # Cookie contains invalid key, so delete cookie
          response.delete_cookie(Session::COOKIE_NAME)
        end
      end
      session
    end

    def new_session
      session = Session.create!(:identity => @current_identity)
      response.set_cookie(Session::COOKIE_NAME,
        :value => session.key,
        :path => '/',
        :expires => Session::DEFAULT_EXPIRY.dup)
      session
    end

    def current_identity
      return @current_identity ||= current_session.identity
    end

    def log_in(identity)
      if current_identity != identity
        current_session.identity = identity
        current_session.save!
        @current_identity = identity
      end
    end

    def log_out
      if current_session.identity and not current_session.identity.provisional?
        current_session.identity = nil
        current_session.save!
      end
      @current_identity = nil      
    end

    def check_god_credentials(realm_id)
      unless current_identity.try(:god?) && current_identity.realm_id == realm_id
        halt 403, "You must be a god of the '#{Realm.find_by_id(realm_id).label}'-realm"
      end
    end

    def check_root_credentials
      unless current_identity && current_identity.root?
        halt 403, "You must be a god of the root realm"
      end
    end

    def current_realm
      @current_realm ||= Realm.find_by_url(request.host)
    end

    def find_realm_by_label(label)
      realm = current_realm if label == 'current'
      realm ||= Realm.find_by_label(label)
      halt 200, "{}" unless realm
      realm
    end
  end
end
