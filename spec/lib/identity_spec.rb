require 'activerecord_helper'
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

  let(:account_data) {
    account_data = {
      'provider' => 'facebook',
      'uid' => 'abc123',
      'realm_id' => 1,
      'enrolled_by_identity_id' => 2,
      'user_info' => {'name' => 'Tracy Jean', 'email' => 'tracy@thesixties.com', 'mobile' => '99887766'},
      'kind' => Species::User
    }
  }

  # Do we /really/ want to create stubs for all of someone's friends?
  # Also, if you were a stub, but now we have your data... are you now a user?
  describe "#create_or_update" do
    it "creates missing identity" do
      person = Identity.create_or_update(account_data)
      person.enrolled_by_provider.should eq('facebook')
      person.enrolled_by_identity_id.should eq(2)
      person.byline_name.should eq('Tracy Jean')
      person.email.should eq('tracy@thesixties.com')
      person.mobile.should eq('99887766')
      person.should be_user
      person.realm_id.should eq(1)
    end

    it "updates existing identity" do
      existing = {
        :byline_name => 'Tracy Collins',
        :email => 'tracy@oldhound.com',
        :mobile => '99988777',
        :enrolled_by_provider => 'google',
        :enrolled_by_identity_id => 3,
        :realm_id => 1
      }
      existing = Identity.create!(existing)
      Account.create!(:realm_id => 1, :provider => :facebook, :uid => 'abc123', :identity => existing)

      person = Identity.create_or_update(account_data)
      person.enrolled_by_provider.should eq('google')
      person.enrolled_by_identity_id.should eq(3)
      person.byline_name.should eq('Tracy Collins')
      person.email.should eq('tracy@oldhound.com')
      person.mobile.should eq('99988777')
      person.should be_user
      person.realm_id.should eq(1)
    end

    it "doesn't find/update users from a different realm" do
      existing = {
        :byline_name => 'Tracy Collins',
        :realm_id => 2
      }
      existing = Identity.create!(existing)
      Account.create!(:realm_id => 2, :provider => :facebook, :uid => 'abc123', :identity => existing)

      person = Identity.create_or_update(account_data)

      existing.id.should_not eq(person.id)
      person.realm_id.should eq(1)
    end
  end

end
