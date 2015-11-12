require 'spec_helper'

describe Identity do
  context "updating session manager" do
    let :realm do
      Realm.create!(:label => 'realm')
    end

    let :someone do
      Identity.create!(:realm => realm)
    end

    let :account1 do
      Account.create!(:identity => someone,
        :realm => realm,
        :uid => '1',
        :provider => 'twitter',
        :name => "account1")
    end

    let :account2 do
      Account.create!(:identity => someone,
        :realm => realm,
        :uid => '1',
        :provider => 'facebook',
        :name => 'account2')
    end

    it "can read throught a cache" do
      identity = someone
      result = Identity.cached_find_by_id(identity.id)
      result.should eq identity
      attributes = result.attributes
      attributes[:god] = true
      $memcached.set(result.cache_key, attributes.to_json)
      from_cache = Identity.cached_find_by_id(identity.id)
      from_cache.god?.should be_truthy
    end

    it "can read a collection through a cache" do
      identities = (1..20).map { Identity.create!(:realm => realm) }
      from_db = Identity.cached_find_all_by_id(identities[0..10].map(&:id))
      from_db.map(&:id).should eq from_db[0..10].map(&:id)
      # Spoof all cached identities as gods
      from_db.each do |identity|
        attributes = identity.attributes.merge({'god' => true})
        $memcached.set(identity.cache_key, attributes.to_json)
      end
      from_db_and_cache = Identity.cached_find_all_by_id(identities[0..20].map(&:id))
      # Check all gods
      from_db_and_cache[0..10].map(&:god).inject(true){|r, e| r && e}.should be_truthy
      # Check all muggles
      from_db_and_cache[11..19].map(&:god).inject(true){|r, e| r && !e}.should be_truthy
    end

    it "can retrieve a user from a session_key" do
      me = someone
      session = Session.create!(:identity => me)
      Identity.find_by_session_key(session.key).should eq me
      # Again from cache
      Identity.find_by_session_key(session.key).should eq me
    end

    it "automatically destroys all sessions when destroyed" do
      me = someone
      session = Session.create!(:identity => me)
      me.destroy
      Session.find_by_id(session.id).should be_nil
    end

    it "initializes the last_seen_on for new identitites" do
      Identity.find(someone.id).last_seen_on.should eq Time.now.to_date
    end

    it "can find identities not seen for a while" do
      (0..9).each do |age|
        # FIXME: We should store time zone in database to avoid UTC conversion
        Identity.create!(:realm => realm, :last_seen_on => (Time.now - age.days).utc)
      end
      Identity.not_seen_for_more_than_days(20).size.should eq 0
      Identity.not_seen_for_more_than_days(9).size.should eq 0
      Identity.not_seen_for_more_than_days(8).size.should eq 1
      Identity.not_seen_for_more_than_days(1).size.should eq 8
      Identity.not_seen_for_more_than_days(0).size.should eq 9
    end

    it "can find anonymous identities" do
      someone
      Identity.anonymous.all.first.should eq someone
      account1.identity = someone
      account1.save!
      someone.ensure_primary_account
      someone.save!
      Identity.anonymous.all.size.should eq 0
    end

    describe "#fingerprints" do
      let :identity do
        Identity.new(:realm => realm)
      end

      it 'is empty if no accounts' do
        identity.accounts.should == []
        identity.fingerprints.should == []
      end

      it 'collects fingerprints from all accounts (when adding accounts directly)' do
        identity.accounts << Account.new(:identity => identity, :uid => '123', :provider => 'facebook', :realm => realm)
        identity.accounts << Account.new(:identity => identity, :uid => '234', :provider => 'twitter', :realm => realm)
        identity.fingerprints.length.should >= identity.accounts.length
        identity.fingerprints.sort.should == identity.accounts.map { |a| a.fingerprints }.flatten.sort
      end

      it 'collects fingerprints from all accounts (when creating accounts independently)' do
        Account.create!(:identity => identity, :uid => '123', :provider => 'facebook', :realm => realm)
        Account.create!(:identity => identity, :uid => '234', :provider => 'twitter', :realm => realm)
        identity.reload
        identity.fingerprints.length.should >= identity.accounts.length
        identity.fingerprints.sort.should == identity.accounts.map { |a| a.fingerprints }.flatten.sort
      end

      it 'preserves fingerprint after account is deleted' do
        account = Account.create!(:identity => identity, :uid => '123', :provider => 'facebook', :realm => realm)
        identity.reload
        old_fingerprints = identity.fingerprints.dup
        account.destroy

        identity.reload
        identity.fingerprints.should == old_fingerprints
      end
    end

    describe "#search" do
      let :twitter_account do
        Account.create!(:identity => someone,
          :realm => realm,
          :uid => '1',
          :provider => 'twitter',
          :nickname => 'tildetwitt',
          :name => "Tilde Tjohei Nielsen Babar")
      end
      let :facebook_account do
        Account.create!(:identity => someone,
          :realm => realm,
          :uid => '1',
          :provider => 'facebook',
          :nickname => 'tildeface',
          :name => "Tilde Mehe Nielsen")
      end

      before(:each) do
        twitter_account
        facebook_account
      end

      it "finds users identity from accounts with fuzzy match" do
        result = Identity.find_by_query("Tilde Nielsen")
        result.length.should eq 1
        result.first.accounts.map(&:nickname).sort.should == ['tildeface', 'tildetwitt']
      end

      it "finds users identity from accounts with exact match" do
        result = Identity.find_by_query('"Tilde Nielsen"')
        result.length.should eq 0
        result = Identity.find_by_query('"Tilde Mehe Nielsen"')
        result.length.should eq 1
      end

    end

    describe "#root?" do
      let(:root) { Realm.create!(:label => 'root') }

      it "has root" do
        he = Identity.new(:realm => root, :god => true)
        he.should be_root
      end

      it "is not root if just a regular guy" do
        he = Identity.new(:realm => root, :god => false)
        he.should_not be_root
      end

      it "is not root if god in a different realm" do
        he = Identity.new(:realm => realm, :god => true)
        he.should_not be_root
      end

    end

  end
end
