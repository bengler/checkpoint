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

describe "Transfers" do

  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

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

  describe 'POST /transfer/token' do
    it 'creates token and secret' do      
      post '/transfer/token', {},
        'HTTP_REFERER' => 'http://example.org/',
        'HTTP_ACCEPT' => 'application/json'
      last_response.status.should eq 201
      last_response.content_type.should =~ %r{application/json}
      data = JSON.parse(last_response.body)
      data.should include('token')
      data.should include('secret')
      
      token = TransferToken.find(data['token'])
      token.should_not == nil
      token.secret.should == data['secret']
      token.valid_referrer?('http://example.org/').should == true
      token.valid_referrer?('http://example.org/very/special/page').should == true
      token.valid_referrer?('http://example.com/').should == false
    end
  end

  describe 'GET /transfer/:token' do
    let :token do
      TransferToken.generate("http://example.org/")
    end

    it 'sets session and redirects back' do
      get "/transfer/#{token.token}", {:return_url => 'http://example.org/'},
        'HTTP_REFERER' => 'http://example.org/',
        'HTTP_ACCEPT' => 'application/json'
      last_response.status.should == 302
      last_response.location.should =~ %r{^http://example.org/}
      params = CGI.parse(URI.parse(last_response.location).query)
      params.should_not include('error')
      params.should include('session_key')
      params.should include('signature')
      params['signature'][0].should == token.sign_with_secret(params['session_key'][0])
    end

    it 'redirects back to referrer if no return URL' do
      get "/transfer/#{token.token}", {},
        'HTTP_REFERER' => 'http://example.org/',
        'HTTP_ACCEPT' => 'application/json'
      last_response.status.should == 302
      last_response.location.should =~ %r{^http://example.org/}
      params = CGI.parse(URI.parse(last_response.location).query)
      params.should_not include('error')
      params.should include('session_key')
      params.should include('signature')
      params['signature'][0].should == token.sign_with_secret(params['session_key'][0])
    end

    it 'rejects invalid referrer' do
      get "/transfer/#{token.token}", {:return_url => 'http://example.org/'},
        'HTTP_REFERER' => 'http://example.com/',
        'HTTP_ACCEPT' => 'application/json'
      last_response.status.should == 302
      last_response.location.should =~ %r{^http://example.org/}
      params = CGI.parse(URI.parse(last_response.location).query)
      params.should include('error')
      params['error'][0].should == 'invalid_return'
    end

    it 'rejects invalid return URL' do
      get "/transfer/#{token.token}", {:return_url => 'http://example.com/'},
        'HTTP_REFERER' => 'http://example.org/',
        'HTTP_ACCEPT' => 'application/json'
      last_response.status.should == 302
      last_response.location.should =~ %r{^http://example.com/}
      params = CGI.parse(URI.parse(last_response.location).query)
      params.should include('error')
      params['error'][0].should == 'invalid_return'
    end

    it 'rejects invalid token' do
      get "/transfer/123456789", {:return_url => 'http://example.org/'},
        'HTTP_REFERER' => 'http://example.org/',
        'HTTP_ACCEPT' => 'application/json'
      last_response.status.should == 302
      last_response.location.should =~ %r{^http://example.org/}
      params = CGI.parse(URI.parse(last_response.location).query)
      params.should include('error')
      params['error'][0].should == 'invalid_token'
    end
  end

end
