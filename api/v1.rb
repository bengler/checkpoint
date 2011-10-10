# encoding: utf-8
require "json"

Dir.glob("#{File.dirname(__FILE__)}/v1/**").each{ |file| require file }

class CheckpointV1 < Sinatra::Base

  helpers do 
    def api_version
      @api_version ||= self.class.name.scan(/\d+$/).first
    end

    def api_path(path)
      path = "/#{path}" unless path[0] == '/'
      "/api/v#{api_version}#{path}"
    end
  end

  get '/' do
    <<-HTML
      <a href='/api/v1/auth/twitter'>Sign in with Twitter</a>
    HTML
  end

end
