require 'spec_helper'
require 'client_helper'

describe Identity do
  let(:atle) { Identity.new }

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
    let(:user) { Identity.create(:realm_id => 1) }
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

end
