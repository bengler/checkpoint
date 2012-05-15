require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Session cookies" do

  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let! :realm do
    Realm.create!(:label => "area51")
  end

  let! :primary_domain do
    domain = Domain.create!(:name => 'example.com', :realm => realm)
    realm.primary_domain = domain
    realm.save!
    domain
  end

  let! :secondary_domain do
    Domain.create!(:name => 'example.org', :realm => realm)
  end

  it 'automatically sets a session cookie' do
    rack_mock_session.cookie_jar['checkpoint.session'].should == nil
    get "/identities/me", {}, {'HTTP_HOST' => 'example.com'}
    last_response.status.should eq 200
    last_response.headers.should include('Set-Cookie')
    rack_mock_session.cookie_jar['checkpoint.session'].should_not == nil
  end

  it 'sets a long expiry on primary domain session cookie' do
    rack_mock_session.cookie_jar['checkpoint.session'].should == nil
    get "/identities/me", {}, {'HTTP_HOST' => 'example.com'}
    last_response.status.should eq 200
    last_response.headers.should include('Set-Cookie')
    if last_response.headers['Set-Cookie'] =~ /expires=([^;]+)/
      expiry = Time.parse($1)
    else
      expiry = nil
    end
    expiry.should >= Time.now + 63113851
  end

  it 'sets no expiry on secondary domain session cookie' do
    rack_mock_session.cookie_jar['checkpoint.session'].should == nil
    get "/identities/me", {}, {'HTTP_HOST' => 'example.org'}
    last_response.status.should eq 200
    last_response.headers.should include('Set-Cookie')
    last_response.headers['Set-Cookie'].should_not =~ /expires=/
  end

end
