require 'omniauth/oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    # OAuth 2.0 based authentication with Origo. In order to
    # sign up for an application, you need to [register an application](http://origo.no/-/admin/external_application/new)
    # and provide the proper credentials to this middleware.
    class Origo < OAuth2

      include OmniAuth::Strategy

      # @param [Rack Application] app standard middleware application argument
      # @param [String] client_id the application ID for your client
      # @param [String] client_secret the application secret
      def initialize(app, client_id = nil, client_secret = nil, options = {}, &block)
        client_options = {
          :site => 'http://secure.origo.no',
          :authorize_path => '/-/oauth/authorize',
          :access_token_path => '/-/oauth/token'
        }
        super(app, :origo, client_id, client_secret, client_options, options, &block)
      end

      protected

      def user_data
        @data ||= MultiJson.decode(@access_token.get('/-/api/v2/js/user'))
      end

      def user_info
        {
          'name' => user_data['result']['user']['full_name'],
          'first_name' => user_data['result']['user']['first_name'],
          'last_name' => user_data['result']['user']['last_name'],
          'image' => user_data['result']['user']['image_url'],          
          'urls' => {
            'Origo' => "http://origo.no/-/user/show/#{user_data['result']['user']['id']}"
          }
        }
      end

      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
          'uid' => user_data['result']['user']['id'].to_s,
          'user_info' => user_info,
          'extra' => {'user_hash' => user_data}
        })
      end
    end
  end
end
