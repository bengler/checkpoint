require 'spec_helper'

describe Account do


  let :realm do
    realm = Realm.create!(:label => "area51")
    Domain.create!(:realm => realm, :name => 'example.org')
    realm
  end

  let(:account) { Account.new(:provider => :facebook, :uid => 'abc123', :realm => realm, :token => 'token', :secret => 'secret') }

  let :identity do
    Identity.create!(:realm => realm)
  end

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

  describe '#fingerprint' do
    it 'returns fingerprint' do
      account.fingerprints.length.should > 0
      account.fingerprints.each do |f|
        f.should =~ /\A[a-z0-9]+\z/
      end
    end

    it 'changes when uid changes' do
      old_fingerprints = account.fingerprints
      account.uid = "barsoom"
      account.fingerprints.should_not == old_fingerprints
    end

    it 'changes when provider changes' do
      old_fingerprints = account.fingerprints
      account.provider = "barsoom"
      account.fingerprints.should_not == old_fingerprints
    end

    it 'changes only according to uid and provider' do
      old_fingerprints = account.fingerprints
      account.attributes.each do |k, v|
        unless %(uid provider).include?(k.to_s)
          case v
            when String
              account.attributes[k] = "#{v}barsoom"
            when Fixnum
              account.attributes[k] = v + 1
            else
              account.attributes[k] = "barsoom"
          end
        end
      end
      account.fingerprints.should == old_fingerprints
    end
  end

  describe "#credentials" do
    it "finds keys for a specific identity and provider" do
      keys = Account.create!(:provider => :facebook, :uid => 'abc123', :realm => realm, :token => 'token', :secret => 'secret', :identity => identity)
      account = Account.find_by_identity_id_and_provider(identity.id, :facebook)
      account.should_not == nil
      account.credentials.should eq({:token => 'token', :secret => 'secret'})
      account.authorized?.should be_true
    end

    it "ignores keys where token/secret are missing" do
      Account.create!(:provider => :facebook, :uid => 'abc123', :realm => realm, :identity => identity)
      account = Account.find_by_identity_id_and_provider(identity.id, :facebook)
      account.should_not == nil
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
       "info"=>
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
       "info"=>
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

    it "declaring the same account twice should yield the same account with the same identity" do
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account2 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account1.identity.should eq account2.identity
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

    it "cannot be bound to an identity if it already is attached to another" do
      # Create two different identitites for the same physical person
      account_with_twitter = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account_with_facebook = Account.declare_with_omniauth(facebook_auth, :realm => realm)

      # Try to attach the twitter account to the identity formerly having just a FB-account.
      lambda {
        Account.declare_with_omniauth(twitter_auth, :identity => account_with_facebook.identity)
      }.should raise_error(Account::InUseError)
    end


    it "sets a primary account when the identity is first created" do
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account1.identity.primary_account.should eq account1
      account2 = Account.declare_with_omniauth(facebook_auth, :identity => account1.identity)
      account1.identity.primary_account.should eq account1
    end

    it "unsets primary_account when an account is deleted" do
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      identity = account1.identity
      identity.reload
      identity.primary_account.should eq account1
      account1.destroy
      identity.reload
      identity.primary_account.should be_nil
    end

    it "silently picks a different primary_account when one of many accounts is deleted" do
      account1 = Account.declare_with_omniauth(twitter_auth, :realm => realm)
      account2 = Account.declare_with_omniauth(facebook_auth, :identity => account1.identity)
      identity = account1.identity
      identity.primary_account.should eq account1
      account1.destroy
      identity.reload
      identity.primary_account.should eq account2
    end

  end
end
