require 'spec_helper'
require 'client_helper'

describe Identity do
  let(:atle) { Identity.new }

  describe "validations" do
    it "is invalid if the kind is unknown" do
      atle.kind = 42
      atle.should_not be_valid
    end
  end

  describe "integrates with species" do
    it "recognizes god users" do
      Identity.new(:kind => Species::God).should be_god
    end

    it "knows when a user is not divine" do
      Identity.new.should_not be_god
    end

    it "defaults to 'stub'" do
      Identity.new.should be_stub
    end
  end

  context "with missing credentials" do
    specify "facebook client is unavailable" do
      ->{atle.client_for(:facebook)}.should raise_error(Identity::NotAuthorized)
    end

    specify "twitter client is unavailable" do
      ->{atle.client_for(:twitter)}.should raise_error(Identity::NotAuthorized)
    end

    specify "origo client is unavailable" do
      ->{atle.client_for(:origo)}.should raise_error(Identity::NotAuthorized)
    end
  end

  context "with existing account" do
    let(:user) { Identity.create(:kind => Species::User, :realm_id => 1) }
    before :each do
      # get rid of incidental stuff in initializer
      TwitterClient.any_instance.stub(:configure)
    end

    specify "facebook client is available" do
      credentials = Account.create!(:realm_id => 1, :identity => user, :provider => :facebook, :token => 'facebook_token', :secret => 'facebook_secret', :uid => 'abc123')
      user.client_for(:facebook).class.should eq(FacebookClient)
    end

    specify "twitter client is available" do
      credentials = Account.create!(:realm_id => 1, :identity => user, :provider => :twitter, :token => 'twitter_token', :secret => 'twitter_secret', :uid => 'abc123')
      user.client_for(:twitter).class.should eq(TwitterClient)
    end

    specify "origo client is available" do
      credentials = Account.create!(:realm_id => 1, :identity => user, :provider => :origo, :token => 'origo_token', :secret => 'origo_secret', :uid => 'abc123')
      user.client_for(:origo).class.should eq(OrigoClient)
    end
  end

  describe "promotions" do
    let(:bob) { Identity.new }
    it "promotes to user" do
      bob.promote_to(Species::User)
      bob.should be_user
    end

    it "promotes to admin" do
      bob.promote_to(Species::Admin)
      bob.should be_admin
    end

    it "promotes admin to god" do
      bob.promote_to(Species::God)
      bob.should be_god
    end

    it "does not demote god" do
      bob.kind = Species::God
      bob.promote_to(Species::Admin)
      bob.should be_god
    end

    it "does not demote admin" do
      bob.kind = Species::Admin
      bob.promote_to(Species::User)
      bob.should be_admin
    end
  end

  context "Integration Specs" do
    describe "#establish with twitter" do
      let(:auth_data) do
        {
          "realm_id" => 1,
          "provider" => "twitter",
          "uid" => "123",
          "credentials" => {"token" => "token", "secret" => "secret"},
          "user_info" => {
          "nickname" => "handle", "name" => "Bob Smith", "location" => "Oslo, Norway", "image" => "http://profile-pic.jpg", "description" => "I do stuff, and I'm awesome.", "urls" => {"Website" => nil, "Twitter" => "http://twitter.com/handle"}
        },
          "extra" => {"access_token"=> stub}
        }
      end

      it "locates existing identity" do
        identity = Identity.create!(:realm_id => 1)
        account = Account.create!(:identity_id => identity.id, :realm_id => identity.realm_id, :provider => :twitter, :uid => '123')

        Identity.establish(auth_data).should eq(identity)
      end

      it "authorizes a stub" do
        identity = Identity.create!(:realm_id => 1)
        account = Account.create!(:identity_id => identity.id, :realm_id => identity.realm_id, :provider => :twitter, :uid => '123')

        Identity.establish(auth_data)
        account.reload
        account.credentials.should eq({:token => 'token', :secret => 'secret'})
        account.identity.should be_user
      end

      it "creates new identity with account" do
        identity = Identity.establish(auth_data)
        identity.should be_user

        account = identity.accounts.first
        account.provider.should eq('twitter')
        account.uid.should eq('123')
        account.credentials.should eq({:token => 'token', :secret => 'secret'})
      end

      it "sets byline name on new identity" do
        Identity.establish(auth_data).byline_name.should eq('Bob Smith')
      end
    end

  end
end
