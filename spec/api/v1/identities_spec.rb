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

  let :another_realm do
    realm = Realm.create!(:label => "another")
    Domain.create!(:realm => realm, :name => 'another.org')
    realm
  end

  let :me do
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

  let :someone_from_another_realm do
    identity = Identity.create!(:realm => another_realm)
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

  let! :god do
    Identity.create!(:god => true, :realm => realm)
  end

  let :me_session do
    Session.create!(:identity => me).key
  end

  let :god_session do
    Session.create!(:identity => god).key
  end

  let(:json_output) {
    if last_response.headers['Content-Type'] =~ /application\/json/
      JSON.parse(last_response.body)
    else
      nil
    end
  }

  describe "GET /identities/me" do

    it "is possible to set current session with a http parameter" do
      get "/identities/me", :session => me_session
      identity = JSON.parse(last_response.body)['identity']
      identity['id'].should eq me.id
    end

    it "handles invalid sessions gracefully" do
      get "/identities/me", :session => "invalidsessionhash"
      last_response.status.should eq 200
      last_response.body.should eq '{}'
    end

    it "describes me as a json hash" do
      get "/identities/me", :session => me_session

      identity = json_output['identity']
      identity['id'].should eq me.id
      identity['realm'].should eq me.realm.label

      json_output['accounts'].should eq ['twitter']

      profile = json_output['profile']
      profile['provider'].should eq 'twitter'
      profile['nickname'].should eq 'nickname'
      profile['name'].should eq 'name'
      profile['profile_url'].should eq 'profile_url'
      profile['image_url'].should eq 'image_url'
      # And the result is the same if I ask for me by id
      former_response_body = last_response.body
      get "/identities/#{me.id}", :session => me_session
      last_response.body.should eq former_response_body
    end

    it "hands me my balls if I ask for current user when there is no current user" do
      get "/identities/me"
      last_response.body.should eq "{}"
    end
  end

  describe "GET /identities/:identity_or_identities" do

    it "describes an identity as a json hash" do
      get "/identities/#{god.id}", :session => me_session
      JSON.parse(last_response.body)['identity']['id'].should eq god.id
    end

    it "will not return identities from other realms" do
      get "/identities/#{someone_from_another_realm.id}", :session => me_session
      last_response.status.should eq 200
      last_response.body.should eq "{}"
    end

    it "returns multiple identities" do
      get "/identities/#{god.id},#{me.id}", :session => me_session
      result = JSON.parse(last_response.body)['identities']
      result.first['identity']['id'].should eq god.id
      result.first['accounts'].should eq([])
      result.first['profile'].should be_nil

      result.last['identity']['id'].should eq me.id
      result.last['accounts'].should eq(['twitter'])
      result.last['profile']['provider'].should eq('twitter')
    end

    it "if requesting mulitple identities, it will only return identities from same domain" do
      get "/identities/#{god.id},#{someone_from_another_realm.id},#{me.id}", :session => me_session
      last_response.status.should eq 200
      result = JSON.parse(last_response.body)['identities']
      result.first['identity']['id'].should eq god.id
      result[1]['identity'].should be_empty
      result.last['identity']['id'].should eq me.id
    end

    it "returns empty identities if requested ids do not exist" do
      get "/identities/1024,1025,1026", :session => me_session
      empty_hash = {}
      result = JSON.parse(last_response.body)
      result['identities'].length.should eq 3
      result['identities'][0]['identity'].should eq empty_hash
      result['identities'][1]['identity'].should eq empty_hash
      result['identities'][2]['identity'].should eq empty_hash
    end

    it "can mix existing and non-existant identities" do
      get "/identities/1024,#{me.id},1026,#{god.id}", :session => me_session
      empty_hash = {}
      result = JSON.parse(last_response.body)
      result['identities'].length.should eq 4
      result['identities'][0]['identity'].should eq empty_hash
      result['identities'][1]['identity']['id'].should eq me.id
      result['identities'][2]['identity'].should eq empty_hash
      result['identities'].last['identity']['id'].should eq god.id
    end

    it "hands me a list of a single identity if I ask for it using a comma" do
      get "/identities/#{god.id},", :session => me_session
      result = JSON.parse(last_response.body)
      result['identities'].first['identity']['id'].should eq god.id
    end

    it 'includes fingerprints' do
      get "/identities/#{me.id}", :session => me_session
      result = JSON.parse(last_response.body)
      result['identity']['fingerprints'].sort.should eq me.fingerprints.sort
    end

    it 'includes tags' do
      get "/identities/#{me.id}", :session => me_session
      result = JSON.parse(last_response.body)
      result['identity']['tags'].sort.should eq me.tags.sort
    end
  end

  describe "POST /identities" do
    it "creates an identity with an account" do
      parameters = {:session => god_session, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(201)
      json_output['identity']['id'].should_not be_nil
      json_output['profile']["nickname"].should eq('nick')
    end

    it "can create god users" do
      parameters = {:session => god_session, :identity => {:god => true}, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(201)
      identity = json_output['identity']
      identity['id'].should_not be_nil
      identity['god'].should be_true
      json_output['profile']["nickname"].should eq('nick')
    end

    it "fails to create two identities with the same account information on the same realm" do
      parameters = {:session => god_session, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(201)
      identity_id = JSON.parse(last_response.body)['identity']['id']
      post '/identities', parameters
      last_response.status.should eq(409) # conflict
      JSON.parse(last_response.body)['error']['identity'].should eq identity_id
    end

    it "ignores any realm that is passed in" do
      parameters = {:session => god_session, :identity => {:realm => 'rock_and_roll'}, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(201)

      identity = json_output['identity']
      identity['id'].should_not be_nil
      identity['realm'].should eq('area51')

      profile = json_output['profile']
      profile["nickname"].should eq('nick')
    end

    it "does not allow setting fingerprints" do
      post '/identities', {
        session: god_session,
        identity: {fingerprints: ["faux"]},
      }
      last_response.status.should eq(400)
    end

    it "fails to create identities if not god" do
      parameters = {:session => me_session, :account => {:provider => 'twitter', :nickname => 'nick', :uid => '1'}}
      post '/identities', parameters
      last_response.status.should eq(403)
    end

    it 'saves tags' do
      post "/identities", {
        session: god_session,
        account: {provider: 'twitter', nickname: 'nick', uid: '2'},
        identity: {tags: ['foo was here', 'kilroy was here']}
      }
      result = JSON.parse(last_response.body)
      identity = Identity.where(id: result['identity']['id']).first
      identity.tags.sort.should eq ['foo was here', 'kilroy was here']
      result['identity']['tags'].sort.should eq identity.tags.sort
    end
  end

  describe "PUT /identities/:id" do

    it "requires god powers" do
      put "/identities/#{me.id}", :identity => {:god => true}, :session => me_session
      last_response.status.should eq(403)
    end

    it "will level you up" do
      put "/identities/#{me.id}", :identity => {:god => true}, :session => god_session
      last_response.status.should eq(200)

      JSON.parse(last_response.body)["identity"]["god"].should == true
    end

    it "does not allow setting fingerprints" do
      expected_fingerprints = me.fingerprints.dup
      put "/identities/#{me.id}", {
        session: god_session,
        identity: {fingerprints: ["X"]},
      }
      last_response.status.should eq(400)
      json_output.should eq nil
    end

    it 'saves tags' do
      put "/identities/#{me.id}", {
        session: god_session,
        identity: {
          tags: ['foo was here', 'kilroy was here']
        }
      }
      last_response.status.should eq(200)
      me.reload
      me.tags.sort.should eq ['foo was here', 'kilroy was here']
      json_output['identity']['tags'].sort.should eq me.tags.sort
    end
  end

  describe "last_seen_on" do
    it "stamps the user with a date for when it was last seen" do
      get "/identities/me", :session => me_session
      identities = Identity.cached_find_by_id(me.id)
      identities.last_seen_on.to_date.should eq Time.now.to_date
    end

    it "updates last_seen_on timestamp when it is old" do
      me.last_seen_on = Time.now.to_date-2
      me.save!
      get "/identities/me", :session => me_session
      identity = Identity.cached_find_by_id(me.id)
      identity.last_seen_on.to_date.should eq Time.now.to_date
    end
  end

  describe "provisional status" do
    it "is provisional if there's no account" do
      identity = Identity.create!(:realm => realm)
      session = Session.create!(:identity => identity)
      get "/identities/me", :session => session.key
      JSON.parse(last_response.body)["identity"]["provisional"].should be_true
    end

    it "is not provisional when account is present" do
      get "/identities/me", :session => me_session
      JSON.parse(last_response.body)["identity"]["provisional"].should be_false
    end
  end

  describe "GET /identities/find" do
    let(:tilde_account) do
      identity = Identity.create!(:realm => realm)
      Account.create!(:identity => identity,
        :realm => realm,
        :provider => 'twitter',
        :uid => '1',
        :token => 'token',
        :secret => 'secret',
        :nickname => 'tilde',
        :name => 'Tilde Nielsen')
    end

    let(:foobar_account) do
      identity = Identity.create!(:realm => realm)
      Account.create!(:identity => identity,
        :realm => realm,
        :provider => 'twitter',
        :uid => '2',
        :token => 'token',
        :secret => 'secret',
        :nickname => 'foobar',
        :name => 'Foo Nielsen Bar')
    end

    describe "security" do
      it "is available for everyone" do
        get "/identities/find", :q => "foo", :session => "bar"
        last_response.status.should eq(200)
      end
    end

    describe "query" do
      before(:each) do
        tilde_account
        foobar_account
      end
      it "finds identities and accounts" do
        get "/identities/find", :q => "tilde", :session => god_session
        identities = JSON.parse(last_response.body)["identities"]
        identities.count.should eq 1
        identities.first['profile']['name'].should eq "Tilde Nielsen"
      end
      it "paginates" do
        get "/identities/find", :q => "nielsen", :session => god_session
        identities = JSON.parse(last_response.body)["identities"]
        identities.count.should eq 2
        get "/identities/find", :q => "nielsen", :session => god_session, :limit => 1
        identities = JSON.parse(last_response.body)["identities"]
        identities.count.should eq 1
      end
    end
  end

end
