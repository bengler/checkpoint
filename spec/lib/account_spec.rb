require 'spec_helper'

describe Account do

  let(:account) { Account.new(:provider => :facebook, :uid => 'abc123', :realm_id => 1, :token => 'token', :secret => 'secret') }

  describe 'required attributes' do
    [:uid, :provider, :realm_id].each do |attribute|
      specify "#{attribute} can't be nil" do
        account.attributes = {attribute => nil}
        account.should_not be_valid
      end

      specify "#{attribute} can't be an empty string" do
        account.attributes = {attribute => ''}
        account.should_not be_valid
      end
    end

    specify "uid can contain the usual for usernames" do
      account.uid = 'a-bc_123.go'
      account.should be_valid
    end

    it "accepts unknown providers" do
      account.provider = :unknown_provider
      account.should be_valid
    end

    it "accepts known providers as symbols" do
      account.provider = :facebook
      account.should be_valid
    end

    it "accepts known providers as strings" do
      account.provider = 'facebook'
      account.should be_valid
    end
  end

  describe "#credentials" do
    it "finds keys for a specific identity and provider" do
      keys = Account.create!(:provider => :facebook, :uid => 'abc123', :realm_id => 1, :token => 'token', :secret => 'secret', :identity_id => 37)
      identity = stub(:id => 37)
      account = Account.find_by_identity_id_and_provider(identity.id, :facebook)
      account.credentials.should eq({:token => 'token', :secret => 'secret'})
      account.authorized?.should be_true
    end

    it "ignores keys where token/secret are missing" do
      Account.create!(:provider => :facebook, :uid => 'abc123', :realm_id => 1, :identity_id => 17)
      identity = stub(:id => 17)
      account = Account.find_by_identity_id_and_provider(identity.id, :facebook)
      account.credentials.should be_nil
      account.authorized?.should be_false
    end
  end

  context "declarations" do
    let :realm do
      Realm.create!(:label => 'test')
    end

    let :twitter_auth do
      # A simplified version of the auth-hash from twitter
      {"provider"=>"twitter",
       "uid"=>"6967612",
       "credentials"=>
        {"token"=>"sometoken",
         "secret"=>"somesecret"},
       "user_info"=>
        {"nickname"=>"svale",
         "name"=>"Simen Svale Skogsrud",
         "location"=>"59.916551,10.741328",
         "image"=>
          "http://a1.twimg.com/profile_images/31020282/10962_h0e0f90e04a8393764d3b_180x180_cub_normal.jpg",
         "description"=>"Gartner pa Underskog og vaktmester pa Origo",
         "urls"=>
          {"Website"=>"http://origo.no/simen",
           "Twitter"=>"http://twitter.com/svale"}}}
    end

    let :other_twitter_auth do
      result = twitter_auth.dup
      result["uid"] = "1"
      result
    end

    let :facebook_auth do
      {"provider"=>"facebook",
       "uid"=>"1313666",
       "credentials"=>
        {"token"=>"sometoken",
         "secret"=>"somesecret"},
       "user_info"=>
        {"nickname"=>nil,
         "name"=>"Simen Svale Skogsrud",
         "location"=>"59.916551,10.741328",
         "image"=>
          "http://a1.twimg.com/profile_images/31020282/10962_h0e0f90e04a8393764d3b_180x180_cub_normal.jpg",
         "description"=>"Gartner pa Underskog og vaktmester pa Origo",
         "urls"=>
          {"Website"=>"http://origo.no/simen",
           "Facebook"=>"http://twitter.com/svale"}}}
    end

    it "gets the proper fields set when declared" do
      account = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account.provider.should eq "twitter"
      account.token.should eq "sometoken"
      account.secret.should eq "somesecret"
      account.nickname.should eq "svale"
      account.name.should eq "Simen Svale Skogsrud"
      account.location.should eq "59.916551,10.741328"
      account.image_url.should eq "http://a1.twimg.com/profile_images/31020282/10962_h0e0f90e04a8393764d3b_180x180_cub_normal.jpg"
      account.description.should eq "Gartner pa Underskog og vaktmester pa Origo"
      account.profile_url.should eq "http://twitter.com/svale"
    end

    it "creates identity if missing" do
      account = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account.identity.should be_a_kind_of(Identity)
    end

    it "does not override existing identity" do
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account2 = Account.declare_with_omniauth(facebook_auth, :identity => account1.identity)
      account1.identity.should eq account2.identity
    end

    it "creates different identities for different users" do
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account2 = Account.declare_with_omniauth(other_twitter_auth, :realm => realm)
      account1.identity.should_not eq account2.identity
    end

    it "orphans an identity when an account is attached to a different identity" do
      # Create two different identitites for the same physical person
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account2 = Account.declare_with_omniauth(facebook_auth, :realm => realm)
      # This identity is about to be terminated
      old_identity = account1.identity
      # Attach the twitter account to the identity formerly having just a FB-account. 
      # The identity formerly associated with that account will be orphaned and merged
      account3 = Account.declare_with_omniauth(twitter_auth, :identity => account2.identity)      
      account2.identity.should eq account3.identity
      account2.identity.should_not eq old_identity
      # Check that a reference from the orphaned identity to the current identity has been stored
      OrphanedIdentity.find_by_old_id(old_identity.id).identity.should eq account3.identity
      # Check that the account object was not reused when reattaching to a new identity
      account1.id.should_not eq account3.id
    end

  end
end
