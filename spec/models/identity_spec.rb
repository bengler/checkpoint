require 'spec_helper'

describe Identity do
  let(:atle) { Identity.new(:byline_name => 'Atle') }

  it "can updates its uid-fields with a nifty helper method" do
    atle.facebook_uid.should eq nil
    atle.set_provider_uid('facebook', '1234')
    atle.facebook_uid.should eq "1234"
    ->{atle.set_provider_uid("dingbat", "1234")}.should raise_error(ArgumentError)
  end

  it "can retrieve all relevant credentials" do
    territory = Territory.create!(:label => 'territory', :api_key => 'i3ehr2ioer7y')
    u = Identity.create!(:territory_id => territory.id, :twitter_uid => '1', :facebook_uid => '2', :byline_name => 'pk')
    other_user = Identity.create!(:territory_id => territory.id, :twitter_uid => '3', :facebook_uid => '4', :byline_name => 'kristoffer')

    Authentication.create!(:territory => territory, :identity => u, :provider => 'twitter', :token => 'twitter_token', :secret => 'twitter_secret')
    Authentication.create!(:territory => territory, :identity => u, :provider => 'facebook', :token => 'facebook_token', :secret => 'facebook_secret')
    Authentication.create!(:territory => territory, :identity => other_user, :provider => 'google', :token => 'unwanted', :secret => 'unwanted')

    u = Identity.find(u)
    auth = u.credentials
    auth[:twitter][:token].should eq 'twitter_token'
    auth[:facebook][:secret].should eq 'facebook_secret'
    auth[:google].should eq nil
  end

  describe "implemented providers" do
    context "facebook" do
      specify "uid accessors" do
        atle.set_provider_uid('facebook', '666')
        atle.facebook_uid.should eq('666')

        atle.save
        Identity.find_by_provider_and_uid('facebook', '666').should eq(atle)
      end

      # etc
      xit "gets a profile in the redis store upon creation" do
        u = Identity.create!(:twitter_uid => '1', :facebook_uid => '2', :byline_name => 'pk')
        u.person.byline_name.should eq "pk"
      end
    end

    specify "twitter" do
      atle.set_provider_uid('twitter', '303')
      atle.twitter_uid.should eq('303')

      atle.save
      Identity.find_by_provider_and_uid('twitter', '303').should eq(atle)
    end

    specify "google" do
      atle.set_provider_uid('google', '42')
      atle.google_uid.should eq('42')

      atle.save
      Identity.find_by_provider_and_uid('google', '42').should eq(atle)
    end

    specify "origo" do
      atle.set_provider_uid('origo', '1')
      atle.origo_uid.should eq('1')

      atle.save
      Identity.find_by_provider_and_uid('origo', '1').should eq(atle)
    end

    specify "unknown" do
     ->{atle.set_provider_uid('unknown', '000')}.should raise_error(ArgumentError)
    end
  end

  describe "kinds of users" do
    it "recognizes god users" do
      Identity.new(:kind => Identity::KIND_GOD).should be_god
    end

    it "knows when a user is not divine" do
      Identity.new.should_not be_god
    end

    it "defaults to 'friend'" do
      Identity.create!(:byline_name => 'Birk', :kind => nil).kind.should eq(Identity::KIND_USER_FRIEND)
    end
  end
end
