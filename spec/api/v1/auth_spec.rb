require 'spec_helper'

require 'net/http'
require 'net/https'
require 'cgi'
require 'base64'

class TestCheckpointV1 < CheckpointV1
  use Rack::Session::Cookie, :key => 'checkpoint.cookie',
    :expire_after => 2592000, # In seconds
    :secret => 'ice cream sandwich'
  use OmniAuth::Builder do
    provider :twitter, nil, nil, :setup => true
  end
end

describe "Authorizations" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  def decode_cookie(cookie)
    Marshal.load(cookie.unpack('m').first)
  end

  let(:valid_realm) {
    realm = Realm.create!(:label => 'valid_realm', :service_keys => {})
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
  }

  it "returns a server error when the realm is undefined" do
    test_realm = Realm.create!(:label => 'the_404_test_realm', :service_keys => {})
    Domain.create!(:realm => test_realm, :name => 'www.unknown.com')
    get "/login/twitter"
    last_response.status.should eq 500
  end

  context "with a valid domain" do
    before(:each) { valid_realm } # trigger

    it "redirects to '/auth/:provider' if realm exists" do
      get "/login/twitter"
      last_response.status.should eq 302
      last_response.header['Location'].should =~ /example\.org\/auth\/twitter$/
    end

    it "(optionally) sets a return url" do
      get '/login/twitter', :redirect_to => '/somewhere/else'
      decode_cookie(rack_mock_session.cookie_jar['checkpoint.cookie'])['redirect_to'].should eq('http://example.org/somewhere/else')
    end

    it "(optionally) passes the display param" do
      get '/login/facebook', :display => 'popup'
      decode_cookie(rack_mock_session.cookie_jar['checkpoint.cookie'])['display'].should eq('popup')
    end

    it "configures strategy and redirects to twitter" do
      keys = valid_realm.keys_for(:twitter)
      VCR.use_cassette("twitter_auth_setup") do
        get "/login/twitter" # Just to setup realm
        get "/auth/twitter"
        last_response.status.should eq 302
        last_response.header['Location'].should =~ /https:\/\/api\.twitter\.com\/oauth\/authenticate\?oauth_token=.*/
          strategy = last_request.env['omniauth.strategy']
        strategy.options[:consumer_key].should eq keys.consumer_key
        strategy.options[:consumer_secret].should eq keys.consumer_secret
      end
    end

    it "handles a failed authentication" do
      VCR.use_cassette('refuse_authorization_with_twitter') do
        get '/auth/twitter'
        get '/auth/twitter/callback'
        last_response.status.should eq 302
        last_response.header['Location'].should eq "/auth/failure?message=invalid_credentials&strategy=twitter"
        get "/auth/failure", :message => 'invalid_credentials'
        last_response.status.should eq 302
        last_response.header['Location'].should =~ %r{http://example.org/login/failed}
        last_response.header['Location'].should =~ %r{message=invalid_credentials}
      end
    end

    describe "a provisional identity" do
      it "logs in anonymously" do
        get "/login/anonymous"
        get "/identities/me"
        JSON.parse(last_response.body)['identity']['id'].should_not be_nil
        JSON.parse(last_response.body)['identity']['primary_account'].should be_nil
      end

      it "is not god" do
        get "/login/anonymous"
        get "/identities/me"
        JSON.parse(last_response.body)['identity']['god'].should be_false
      end

      it "cannot log out" do
        get "/login/anonymous"
        get "/identities/me"
        first_response_body = last_response.body
        get "/logout"
        last_response.status.should eq 500
        get "/identities/me"
        last_response.body.should == first_response_body
      end

      it "logs the ip when new anonymous sessions are created" do
        get "/login/anonymous"
        IdentityIp.where(:address => '127.0.0.1').count.should eq 1
      end

      it "redirects to captcha when the ip is hot" do
        rack_mock_session.clear_cookies
        get "/login/anonymous"
        IdentityIp.count.should eq 1
        last_response.location.should_not =~ /captcha/
          rack_mock_session.clear_cookies
        get "/login/anonymous"
        IdentityIp.count.should eq 2
        last_response.location.should_not =~ /captcha/
          rack_mock_session.clear_cookies
        get "/login/anonymous"
        IdentityIp.count.should eq 2
        last_response.location.should =~ /captcha/
      end

      it "redirects to the client after logging in" do
        get "/login/anonymous"
        last_response.status.should eq 302
        last_response.header['Location'].should eq "http://example.org/"
      end
      it "redirects to the path specified by the client" do
        get "/login/anonymous", :redirect_to => "/my_landing_page"
        last_response.status.should eq 302
        last_response.header['Location'].should eq "http://example.org/my_landing_page"
      end
      it "does allow full url in redirect_to parameter" do
        get "/login/anonymous", :redirect_to => "http://another.org/my_landing_page"
        last_response.status.should eq 302
      end
      it "fails if parameter is not a valid url path" do
        get "/login/anonymous", :redirect_to => "\\:/\\some:\\invalid/chars"
        last_response.status.should eq 500
      end

      describe "requested with xhr" do

        it "logs in anonymously" do
          get "/login/anonymous", nil, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
          last_response.status.should eq 200
          get "/identities/me"
          JSON.parse(last_response.body)['identity']['id'].should_not be_nil
          JSON.parse(last_response.body)['identity']['primary_account'].should be_nil
        end

        it "gets a 403 error if the ip is hot" do
          rack_mock_session.clear_cookies
          get "/login/anonymous", nil, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
          last_response.status.should eq 200
          rack_mock_session.clear_cookies
          get "/login/anonymous", nil, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
          last_response.status.should eq 200
          rack_mock_session.clear_cookies
          get "/login/anonymous", nil, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
          last_response.status.should eq 403
        end

        it "gets a 409 error if the user is logged in already" do
          rack_mock_session.clear_cookies
          get "/login/anonymous", nil, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
          last_response.status.should eq 200
          get "/login/anonymous", nil, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
          last_response.status.should eq 409
        end

      end
    end

  end

  context "logging out" do
    let :realm do
      Realm.create!(:label => "area51")
    end

    let :identity do
      identity = Identity.create!(:realm => realm)
      account = Account.create!(:identity => identity,
                                :realm => realm,
                                :provider => 'twitter',
                                :uid => '1',
                                :token => 'token',
                                :secret => 'secret',
                                :nickname => 'nickname',
                                :name => 'name',
                                :profile_url => 'profile_url',
                                :image_url => 'image_url')
      identity.primary_account = account
      identity.save!
      identity
    end

    it "resets identity on logout" do
      session = Rack::MockSession.new(app)
      browser = Rack::Test::Session.new(session)

      session_key = Session.create!(:identity => identity).key

      session.cookie_jar[Session::COOKIE_NAME] = session_key
      session.cookie_jar[Session::COOKIE_NAME + ".sentinel"] = "mocksessionkey"
      session.cookie_jar[Session::COOKIE_NAME].should eq session_key

      browser.get '/logout', {}, 'HTTP_REFERER' => "http://example.org/very/special/page"
      browser.last_response.status.should eq 302
      browser.last_response.header['Location'].should eq "http://example.org/very/special/page"

      Session.identity_id_for_session(session_key).should be_nil
      session.cookie_jar[Session::COOKIE_NAME+".sentinel"].should eq "mocksessionkey"
    end

    it "respects redirect_to parameter when logging out" do
      get "/logout", :redirect_to => "http://wired.com"
      last_response.status.should eq 302
      last_response.location.should eq "http://wired.com"
    end
  end

  context "when authorizing against" do
    before :each do
      valid_realm
    end

    describe "twitter" do
      it "successfully logs in Tilde Nielsen" do
        VCR.use_cassette('authorize_tilde_nielsen_against_twitter') do
          get '/realms/current'

          get '/login/twitter'
          last_response.status.should eq 302
          last_response.header['Location'].should eq('http://example.org/auth/twitter')

          get '/auth/twitter'
          last_response.status.should eq 302
          twitter_auth_url = last_response.header['Location']
          /https:\/\/api\.twitter\.com\/oauth\/authenticate\?oauth_token=(?<oauth_token>.*)/ =~ twitter_auth_url

          oauth_token.should_not be_nil

          uri = URI.parse(twitter_auth_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE

          request = Net::HTTP::Get.new(uri.request_uri)
          response = http.request(request)

          /<input name="authenticity_token" type="hidden" value="(?<authenticity_token>[^"]*)/ =~ response.body

          form_vars = {
            "authenticity_token" => authenticity_token,
            "oauth_token" => oauth_token,
            "session[username_or_email]" => 'tildenielsen',
            "session[password]" => ENV.fetch('CHECKPOINT_TWITTER_PASSWORD') { 'REDACTED:TWITTER_PASSWORD' },
            "allow" => "Sign In"
          }
          the_response = http.post(uri.path, form_vars.map {|k,v| "#{k}=#{CGI.escape(v)}"}.join('&'))

          get '/auth/twitter/callback'
          last_response.status.should eq 302
          last_response.header['Location'].should eq('http://example.org/login/succeeded')
          # Check that the user was actually logged in:
          session_key = rack_mock_session.cookie_jar[Session::COOKIE_NAME]
          session_key.should_not be_nil
          # Check that it created the session in the session store
          identity_id = Session.identity_id_for_session(session_key)
          identity_id.to_i.should > 0
        end
      end

      it "does not store an empty session key in the db" do
        get '/identities/me'
        Session.count.should eq 0
      end

      it "reuses the provided session key even if the session is invalid" do
        VCR.use_cassette('authorize_tilde_nielsen_against_twitter') do
          get '/realms/current'

          # Assign in invalid session key
          rack_mock_session.clear_cookies
          rack_mock_session.cookie_jar[Session::COOKIE_NAME] = "thesessionkey"

          get '/login/twitter'

          get '/auth/twitter'

          twitter_auth_url = last_response.header['Location']
          /https:\/\/api\.twitter\.com\/oauth\/authenticate\?oauth_token=(?<oauth_token>.*)/ =~ twitter_auth_url
          uri = URI.parse(twitter_auth_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          response = http.request(request)
          /<input name="authenticity_token" type="hidden" value="(?<authenticity_token>[^"]*)/ =~ response.body
          form_vars = {
            "authenticity_token" => authenticity_token,
            "oauth_token" => oauth_token,
            "session[username_or_email]" => 'tildenielsen',
            "session[password]" => ENV.fetch('CHECKPOINT_TWITTER_PASSWORD') { 'REDACTED:TWITTER_PASSWORD' },
            "allow" => "Sign In"
          }

          the_response = http.post(uri.path, form_vars.map {|k,v| "#{k}=#{CGI.escape(v)}"}.join('&'))
          get '/auth/twitter/callback'
          last_response.status.should eq 302
          last_response.header['Location'].should eq('http://example.org/login/succeeded')

          # Check that it reused the session key
          session_key = rack_mock_session.cookie_jar[Session::COOKIE_NAME]
          session_key.should eq "thesessionkey"

          # Check that it created the session in the session store
          identity_id = Session.identity_id_for_session(session_key)
          identity_id.to_i.should > 0
        end
      end
    end
  end

  context "when authorizing across domains" do
    let :realm do
      Realm.create!(:label => "area51")
    end

    let :current_domain do
      Domain.create!(:name => "example.org", :realm => realm)
    end

    let :other_domain do
      Domain.create!(:name => "example.com", :realm => realm)
    end

    it "always performs authentication on the primary domain" do
      current_domain
      realm.primary_domain = other_domain
      realm.save

      get '/login/twitter'
      last_response.status.should eq 302
      target_url = "http://#{current_domain.name}/login/succeeded"
      last_response.location.should eq "http://#{other_domain.name}/login/twitter?redirect_to=#{CGI.escape(target_url)}"
    end

    it "proceeds as normal if the current domain is the actual primary domain" do
      realm.primary_domain = current_domain
      realm.save

      get '/login/twitter'
      last_response.status.should eq 302
      last_response.location.should eq "http://#{current_domain.name}/auth/twitter"
    end

  end

  #it "redirects to the override if provided"
  #it "redirects to /login/failed if an exception is raised while handling the callback"
end
