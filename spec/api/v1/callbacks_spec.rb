require 'spec_helper'

class TestCheckpointV1 < CheckpointV1; end

describe "Identities" do
  include Rack::Test::Methods

  def app
    TestCheckpointV1
  end

  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
  end

  let :stranger do
    Identity.create!(:realm => realm)
  end

  let :god do
    Identity.create!(:god => true, :realm => realm)
  end

  let :stranger_session do
    Session.create!(:identity => stranger).key
  end

  let :god_session do
    Session.create!(:identity => god).key
  end

  let(:json_output) { JSON.parse(last_response.body) }

  it "should deny every management action for non-god sessions" do
    get "/callbacks", :session => stranger_session
    last_response.status.should eq 403

    callback = Callback.create!(:path => "area51.a.b.c", :url => "/")
    get "/callbacks/#{callback.id}", :session => stranger_session
    last_response.status.should eq 403

    delete "/callbacks/#{callback.id}", :session => stranger_session
    last_response.status.should eq 403

    post "/callbacks", :session => stranger_session, :callback => { :path => "area51.a.b.c", :url => ""}
    last_response.status.should eq 403
  end

  it "can post a callback" do
    post "/callbacks", :session => god_session, :callback => { :path => "area51.a.b.c", :url => "http://example.org"}
    last_response.status.should eq 201
    callback = Callback.first
    callback.url.should eq "http://example.org"
    callback.path.should eq "area51.a.b.c"
  end

  it "does not create a callback if an identical allready exists" do
    path = "area51.a.b.c"
    url = "http://example.org"
    Callback.create!(:path => path, :url => url)
    count = Callback.count
    post "/callbacks", :session => god_session, :callback => { :path => path, :url => url}
    last_response.status.should eq 200
    Callback.count.should eq count
  end

  it "can provide a list of callbacks" do
    callback1 = Callback.create!(:path => "area51.a.b.c", :url => "http://example.org/1")
    callback2 = Callback.create!(:path => "area51.a.b.d", :url => "http://example.org/2")
    Callback.create!(:path => "other_realm.a", :url => "http://example.com/666") # Should not be seen
    get "/callbacks", :session => god_session
    last_response.status.should eq 200
    result = JSON.parse(last_response.body)
    result['callbacks'].size.should eq 2
    callback_record = result['callbacks'][0]['callback']
    callback_record['url'].should eq callback2.url
    callback_record['path'].should eq callback2.path
    callback_record['id'].should eq callback2.id
  end

  it "can fetch a specific callback" do
    callback2 = Callback.create!(:path => "area51.a.b.d", :url => "http://example.org/2")
    get "/callbacks/#{callback2.id}", :session => god_session
    last_response.status.should eq 200
    result = JSON.parse(last_response.body)
    callback_record = result['callback']
    callback_record['url'].should eq callback2.url
    callback_record['path'].should eq callback2.path
    callback_record['id'].should eq callback2.id
  end

  it "can delete a callback" do
    callback2 = Callback.create!(:path => "area51.a.b.d", :url => "http://example.org/2")
    delete "/callbacks/#{callback2.id}", :session => god_session
    last_response.status.should eq 200
    Callback.count.should eq 0
  end

  context "callbacks" do
    around :each do |example|
      VCR.turned_off do
        example.run
      end
    end

    before :each do
      # A callback that accepts nothing
      stub_http_request(:get, "http://nay.org/?identity=7&method=create&uid=post.blog:area51.b.c.d.e").
         to_return(:status => 200, :body => '{"allow":false, "reason": "You are not worthy"}',
           :headers => {'Content-Type' => 'application/json'})

    end

    it "specifies default rules if there are no callbacks" do
      get "/callbacks/allowed/create/post.blog:area51.b.c"
      last_response.status.should eq 200
      result = JSON.parse(last_response.body)
      result['allowed'].should eq 'default'
    end

    it "denies with a reason" do
      Callback.create!(:path => "area51.b.c", :url => "http://nay.org")
      get "/callbacks/allowed/create/post.blog:area51.b.c.d.e", :identity => 7
      last_response.status.should eq 200
      result = JSON.parse(last_response.body)
      result['allowed'].should be_false
      result['url'].should eq "http://nay.org"
      result['reason'].should eq "You are not worthy"
    end

  end

end