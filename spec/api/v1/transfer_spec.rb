require 'spec_helper'

require 'net/http'
require 'net/https'
require 'cgi'
require 'base64'

class TestCheckpointV1 < CheckpointV1; end

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

  let :target_url do
    "http://#{target_domain.name}/bananas"
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

      get "/transfer", :target => target_url

      last_response.status.should eq 302
      last_response.location.should =~ %r{^http://example.com/api/checkpoint/v1/transfer}

      params = CGI.parse(URI.parse(last_response.location).query)
      params['target'].first.should eq target_url
      params['session'].first.should eq session.key

      # remove stub for current_session_key
      app.filters[:before].pop
    end

    it "receives a transfer at the destination domain, sets the session key and redirects to the final target" do
      get "/transfer", {:target => target_url, :session => session.key},
        {'HTTP_HOST' => target_domain.name}
      last_response.status.should eq 302
      last_response.header["Set-Cookie"].should =~ /#{Session::COOKIE_NAME}=specialsecretsession/
      last_response.location.should eq target_url
    end

    it "receives a transfer at the destination domain, sets the session key even if it's invalid, and redirects to the final target" do
      get "/transfer", {:target => target_url, :session => 'i_do_not_exist'},
        {'HTTP_HOST' => target_domain.name}
      last_response.status.should eq 302
      last_response.header["Set-Cookie"].should =~ /#{Session::COOKIE_NAME}=i_do_not_exist/
      last_response.location.should eq target_url
    end
  end
end
