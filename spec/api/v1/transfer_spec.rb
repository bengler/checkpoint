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

  let :origin_domain do
    Domain.create!(:name => "example.org", :realm => realm)
  end

  let :target_domain do
    Domain.create!(:name => "example.com", :realm => realm)
  end

  let :foreign_domain do
    Domain.create!(:name => "example.net", :realm => Realm.create!(:label => "route66"))
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

  let :session do
    Session.create!(:key => "specialsecretsession", :identity_id => identity.id)
  end

  describe 'GET /transfer' do
    it 'rejects a request to transfer to an unregistered domain' do
      get "/transfer", :target => "http://wired.com/bananas"
      last_response.status.should eq 403
    end

    it 'rejects a request to transfer to a domain registered on another realm' do
      origin_domain # Force creation of origin domain instance
      get "/transfer", :target => "http://#{foreign_domain.name}/bananas"
      last_response.status.should eq 403
    end

    it "accepts a transfer between domains of the same realm and redirects with session info" do
      # There must be a better way to stub sinatra helpers?
      session_key = session.key
      app.before{ self.should_receive(:current_session_key).at_least(1).times.and_return(session_key) }

      origin_domain # Force creation of origin domain instance

      target_url = "http://#{target_domain.name}/bananas"
      get "/transfer", :target => target_url

      last_response.status.should eq 302
      last_response.location.should =~ %r{^http://example.com/api/checkpoint/v1/transfer}

      params = CGI.parse(URI.parse(last_response.location).query)
      params['target'].first.should eq target_url
      params['session'].first.should eq session.key

      # remove stub for current_session_key
      app.filters[:before].pop 
    end

    it "recieves a transfer at the destination domain, sets the session key and redirects to the final target" do
      target_url = "http://#{origin_domain.name}/bananas"
      get "/transfer", :target => target_url, :session => session.key
      last_response.status.should eq 302
      last_response.header["Set-Cookie"].should =~ /checkpoint\.session\=specialsecretsession/
      last_response.location.should eq target_url
    end
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