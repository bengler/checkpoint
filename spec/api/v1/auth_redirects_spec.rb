require 'spec_helper'
require 'base64'

class TestCheckpointV1 < CheckpointV1
  use Rack::Session::Cookie, :key => 'checkpoint.session',
    :expire_after => 2592000, # In seconds
    :secret => 'ice cream sandwich'

  get "/write_to_session/:key" do
    session[params[:key]] = params[:value]
  end

  get "/auth/twitter/setup" do
    "ok"
  end
end

describe "API v1/auth" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  def decode_cookie(cookie)
    Marshal.load(cookie.unpack('m').first)
  end

  it "allows realm to optionally set a redirect_url used for success" do
    Realm.stub(:find_by_label => stub)
    get "/test_realm/auth/twitter?redirect_to=http://example.com"
    last_response.status.should eq 302
    decode_cookie(rack_mock_session.cookie_jar['checkpoint.session'])['redirect_to'].should eq 'http://example.com'
  end

  context "with a successful authentication" do
    before :each do
      Realm.stub(:find_by_label => stub)
      Account.stub(:declare_with_omniauth => stub.as_null_object)
      app.stub(:set_current_identity)
    end

    it "redirects to /login/succeeded page" do
      get '/auth/twitter/setup' # stubbed, to make omniauth happy
      get '/auth/twitter/callback'
      last_response.status.should eq 302
      last_response.header['Location'].should =~ /^http:\/\/example.org\/login\/succeeded$/
    end

    it "redirects to the override if provided" do
      get '/auth/twitter/setup' # stubbed, to make omniauth happy
      get '/write_to_session/redirect_to?value=/other/url'
      get '/auth/twitter/callback'
      last_response.status.should eq 302
      last_response.header['Location'].should =~ /^http:\/\/example.org\/other\/url$/
    end
  end

  context "with a failed authentication" do
    it "redirects to /login/failed if an exception is raised while handling the callback" do
    end
    it "redirects to /login/failed if omniauth proclaims failure"
  end

end
